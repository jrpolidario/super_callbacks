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
    base.send :prepend, Prepended.new
  end

  private

  def self.puts_warning_messages_when_methods_already_defined(base)
    overriden_instance_methods = base.instance_methods(false) & (
      (
        SuperCallbacks::ClassAndInstanceMethods.instance_methods(false) +
        SuperCallbacks::ClassAndInstanceMethods.private_instance_methods(false)
      ) |
      (
        SuperCallbacks::InstanceMethods.instance_methods(false) +
        SuperCallbacks::InstanceMethods.private_instance_methods(false)
      )
    ).sort

    unless overriden_instance_methods.empty?
      puts "WARN: SuperCallbacks will override #{base} the following already existing instance methods: #{overriden_instance_methods}"
    end

    overriden_class_methods = base.methods(false) & (
      (
        SuperCallbacks::ClassAndInstanceMethods.instance_methods(false) +
        SuperCallbacks::ClassAndInstanceMethods.private_instance_methods(false)
      ) |
      (
        SuperCallbacks::ClassMethods.instance_methods(false) +
        SuperCallbacks::ClassMethods.private_instance_methods(false)
      )
    ).sort

    unless overriden_class_methods.empty?
      puts "WARN: SuperCallbacks will override #{base} the following already existing class methods: #{overriden_class_methods}"
    end
  end
end
