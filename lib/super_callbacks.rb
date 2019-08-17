require 'super_callbacks/version'
require 'super_callbacks/helpers'
require 'super_callbacks/prepended'
require 'super_callbacks/class_methods'
require 'super_callbacks/instance_methods'
require 'super_callbacks/class_and_instance_methods'

module SuperCallbacks
  VALID_OPTION_KEYS = [:if].freeze

  def self.included(base)
    # prevent re-including
    return if base.ancestors.detect { |ancestor| ancestor.is_a? SuperCallbacks::Prepended }

    puts_warning_messages_when_methods_already_defined(base)

    base.singleton_class.send :attr_accessor, *[:before_callbacks, :after_callbacks]
    base.send :attr_accessor, *[:before_callbacks, :after_callbacks]
    base.extend ClassMethods
    base.send :include, InstanceMethods
    base.extend ClassAndInstanceMethods
    base.send :include, ClassAndInstanceMethods

    base.singleton_class.send :attr_accessor, :super_callbacks_prepended
    base.super_callbacks_prepended = Prepended.new(base)
    base.send :prepend, base.super_callbacks_prepended

    # needed to fix bug while still support nested callbacks of which methods
    # are defined in the subclasses
    base.singleton_class.send :prepend, InheritancePrepender
  end

  module InheritancePrepender
    def inherited(subclass)
      # need to make a copy of the last SuperCallbacks::Prepended module in the ancestor chain
      # and then `prepend` that module into the newly defined subclass
      first_callbacks_prepended_module_instance = self.ancestors.detect { |ancestor| ancestor.is_a? SuperCallbacks::Prepended }

      new_super_callbacks_prepended = Prepended.new(subclass)

      # ... which could be done via redefining the methods first...
      (
        first_callbacks_prepended_module_instance.instance_methods(false) +
        first_callbacks_prepended_module_instance.private_instance_methods(false)
      ).each do |method_name|
        new_super_callbacks_prepended.send(:define_method, method_name) do |*args|
          # this is the reason why this method needs to be redefined, and not just simply
          # copied from the last SuperCallbacks::Prepended module;
          # because the callback must only run once on the outermost prepended module
          # for details, see spec 'runs the callbacks in correct order when the method is defined in the subclass'
          return super(*args) if self.class.super_callbacks_prepended != subclass.super_callbacks_prepended

          begin
            # refactored to use Thread.current for thread-safetiness
            Thread.current[:super_callbacks_all_instance_variables_before_change] ||= {}
            Thread.current[:super_callbacks_all_instance_variables_before_change][object_id] ||= []

            all_instance_variables_before_change = instance_variables.each_with_object({}) do |instance_variable, hash|
              hash[instance_variable] = instance_variable_get(instance_variable)
            end

            Thread.current[:super_callbacks_all_instance_variables_before_change][object_id] << all_instance_variables_before_change

            run_before_callbacks(method_name, *args)
            super_value = super(*args)
            run_after_callbacks(method_name, *args)
          ensure
            Thread.current[:super_callbacks_all_instance_variables_before_change][object_id].pop

            if Thread.current[:super_callbacks_all_instance_variables_before_change][object_id].empty?
              Thread.current[:super_callbacks_all_instance_variables_before_change].delete(object_id)
            end

            if Thread.current[:super_callbacks_all_instance_variables_before_change].empty?
              Thread.current[:super_callbacks_all_instance_variables_before_change] = nil
            end
          end

          super_value
        end
      end

      subclass.singleton_class.send :attr_accessor, :super_callbacks_prepended
      subclass.super_callbacks_prepended = new_super_callbacks_prepended
      subclass.send :prepend, new_super_callbacks_prepended

      copied_before_callbacks = Helpers.deep_array_and_hash_dup(first_callbacks_prepended_module_instance.base.before_callbacks)
      copied_after_callbacks = Helpers.deep_array_and_hash_dup(first_callbacks_prepended_module_instance.base.after_callbacks)

      subclass.instance_variable_set(:@before_callbacks, copied_before_callbacks)
      subclass.instance_variable_set(:@after_callbacks, copied_after_callbacks)

      subclass.singleton_class.send :prepend, InheritancePrepender
      super
    end
  end

  private

  def self.puts_warning_messages_when_methods_already_defined(base)
    overriden_instance_methods = (
      base.instance_methods(false) & (
        (
          SuperCallbacks::ClassAndInstanceMethods.instance_methods(false) +
          SuperCallbacks::ClassAndInstanceMethods.private_instance_methods(false)
        ) |
        (
          SuperCallbacks::InstanceMethods.instance_methods(false) +
          SuperCallbacks::InstanceMethods.private_instance_methods(false)
        )
      )
    ).sort

    unless overriden_instance_methods.empty?
      puts "WARN: SuperCallbacks will override #{base} the following already existing instance methods: #{overriden_instance_methods}"
    end

    overriden_class_methods = (
      base.methods(false) & (
        (
          SuperCallbacks::ClassAndInstanceMethods.instance_methods(false) +
          SuperCallbacks::ClassAndInstanceMethods.private_instance_methods(false)
        ) |
        (
          SuperCallbacks::ClassMethods.instance_methods(false) +
          SuperCallbacks::ClassMethods.private_instance_methods(false)
        )
      )
    ).sort

    unless overriden_class_methods.empty?
      puts "WARN: SuperCallbacks will override #{base} the following already existing class methods: #{overriden_class_methods}"
    end
  end
end
