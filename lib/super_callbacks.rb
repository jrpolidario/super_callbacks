require 'super_callbacks/version'

module SuperCallbacks
  VERSION = '1.0.0'.freeze

  VALID_OPTION_KEYS = [:if].freeze

  def self.included(base)
    base.singleton_class.send :attr_accessor, *[:before_callbacks, :after_callbacks]
    base.send :attr_accessor, *[:before_callbacks, :after_callbacks]
    base.extend ClassMethods
    base.send :include, InstanceMethods
    base.extend ClassAndInstanceMethods
    base.send :include, ClassAndInstanceMethods
    base.send :prepend, Prepended.new
  end

  class Prepended < Module
  end

  module Helpers
    # (modified) File activesupport/lib/active_support/core_ext/hash/deep_merge.rb, line 18
    def self.deep_merge_hashes(this_hash, other_hash, &block)
      deep_merge_hashes!(this_hash.dup, other_hash, &block)
    end

    # (modified) File activesupport/lib/active_support/core_ext/hash/deep_merge.rb, line 23
    def self.deep_merge_hashes!(this_hash, other_hash, &block)
      this_hash.merge!(other_hash) do |key, this_val, other_val|
        if this_val.is_a?(Hash) && other_val.is_a?(Hash)
          self.deep_merge_hashes(this_val, other_val, &block)
        elsif block_given?
          block.call(key, this_val, other_val)
        else
          other_val
        end
      end
    end

    def self.deep_merge_hashes_and_combine_arrays(this_hash, other_hash, &block)
      self.deep_merge_hashes_and_combine_arrays!(this_hash.dup, other_hash, &block)
    end

    def self.deep_merge_hashes_and_combine_arrays!(this_hash, other_hash, &block)
      this_hash.merge!(other_hash) do |key, this_val, other_val|
        if this_val.is_a?(Hash) && other_val.is_a?(Hash)
          self.deep_merge_hashes(this_val, other_val, &block)
        elsif this_val.is_a?(Array) && other_val.is_a?(Array)
          this_val + other_val
        elsif block_given?
          block.call(key, this_val, other_val)
        else
          other_val
        end
      end
    end
  end

  module ClassAndInstanceMethods
    def before!(method_name, *remaining_args)
      raise ArgumentError, "`#{method_name}` is not or not yet defined for #{self}" unless method_defined? method_name
      before(method_name, *remaining_args)
    end

    def after!(method_name, *remaining_args)
      raise ArgumentError, "`#{method_name}` is not or not yet defined for #{self}" unless method_defined? method_name
      before(method_name, *remaining_args)
    end

    def before(method_name, callback_method_name = nil, options = {}, &callback_proc)
      callback_method_name_or_proc = callback_proc || callback_method_name
      unless [Symbol, String, Proc].any? { |klass| callback_method_name_or_proc.is_a? klass }
        raise ArgumentError, "Only `Symbol`, `String` or `Proc` allowed for `method_name`, but is #{callback_method_name_or_proc.class}"
      end

      invalid_option_keys = options.keys - VALID_OPTION_KEYS
      unless invalid_option_keys.empty?
        raise ArgumentError, "Invalid `options` keys: #{invalid_option_keys}. Valid are only: #{VALID_OPTION_KEYS}"
      end
      if options[:if] && !([Symbol, String, Proc].any? { |klass| callback_method_name_or_proc.is_a? klass })
        raise ArgumentError, "Only `Symbol`, `String` or `Proc` allowed for `options[:if]`, but is #{options[:if].class}"
      end

      self.before_callbacks ||= {}
      self.before_callbacks[method_name.to_sym] ||= []
      self.before_callbacks[method_name.to_sym] << [callback_method_name_or_proc, options[:if]]

      _callbacks_prepended_module_instance = callbacks_prepended_module_instance

      # dont redefine, to save cpu cycles
      unless _callbacks_prepended_module_instance.method_defined? method_name
        _callbacks_prepended_module_instance.send(:define_method, method_name) do |*args|
          run_before_callbacks(method_name, *args)
          super_value = super(*args)
          run_after_callbacks(method_name, *args)
          super_value
        end
      end
    end

    def after(method_name, callback_method_name = nil, options = {}, &callback_proc)
      callback_method_name_or_proc = callback_proc || callback_method_name
      unless [Symbol, String, Proc].include? callback_method_name_or_proc.class
        raise ArgumentError, "Only `Symbol`, `String` or `Proc` allowed for `method_name`, but is #{callback_method_name_or_proc.class}"
      end

      invalid_option_keys = options.keys - VALID_OPTION_KEYS
      unless invalid_option_keys.empty?
        raise ArgumentError, "Invalid `options` keys: #{invalid_option_keys}. Valid are only: #{VALID_OPTION_KEYS}"
      end
      if options[:if] && ![Symbol, String, Proc].include?(options[:if].class)
        raise ArgumentError, "Only `Symbol`, `String` or `Proc` allowed for `options[:if]`, but is #{options[:if].class}"
      end

      self.after_callbacks ||= {}
      self.after_callbacks[method_name.to_sym] ||= []
      self.after_callbacks[method_name.to_sym] << [callback_method_name_or_proc, options[:if]]

      _callbacks_prepended_module_instance = callbacks_prepended_module_instance

      # dont redefine, to save cpu cycles
      unless _callbacks_prepended_module_instance.method_defined? method_name
        _callbacks_prepended_module_instance.send(:define_method, method_name) do |*args|
          run_before_callbacks(method_name, *args)
          super_value = super(*args)
          run_after_callbacks(method_name, *args)
          super_value
        end
      end
    end

    # TODO
    # def around
    # end
  end

  module ClassMethods

    private

    def callbacks_prepended_module_instance
      ancestors.reverse.detect { |ancestor| ancestor.is_a? SuperCallbacks::Prepended }
    end
  end

  module InstanceMethods
    # TODO: optimize by instead of dynamically getting all_ancestral_after_callbacks on runtime
    # set them immediately when `include` is called on Base class
    def run_before_callbacks(method_name, *args)
      all_ancestral_before_callbacks = self.class.ancestors.reverse.each_with_object({}) do |ancestor, hash|
        SuperCallbacks::Helpers.deep_merge_hashes_and_combine_arrays!(
          hash,
          ancestor.instance_variable_get(:@before_callbacks) || {}
        )
      end

      singleton_class_before_callbacks = instance_variable_get(:@before_callbacks) || {}

      all_before_callbacks = SuperCallbacks::Helpers.deep_merge_hashes_and_combine_arrays(
        all_ancestral_before_callbacks,
        singleton_class_before_callbacks
      )

      all_before_callbacks_on_method = all_before_callbacks[method_name] || []

      all_before_callbacks_on_method.each do |before_callback, options_if|
        is_condition_truthy = true

        if options_if
          is_condition_truthy = instance_exec *args, &options_if
        end

        if is_condition_truthy
          if before_callback.is_a? Proc
            instance_exec *args, &before_callback
          else
            send before_callback
          end
        end
      end
    end

    # TODO: optimize by instead of dynamically getting all_ancestral_after_callbacks on runtime
    # set them immediately when `include` is called on Base class
    def run_after_callbacks(method_name, *args)
      all_ancestral_after_callbacks = self.class.ancestors.reverse.each_with_object({}) do |ancestor, hash|
        SuperCallbacks::Helpers.deep_merge_hashes_and_combine_arrays!(
          hash,
          ancestor.instance_variable_get(:@after_callbacks) || {}
        )
      end

      singleton_class_after_callbacks = instance_variable_get(:@after_callbacks) || {}

      all_after_callbacks = SuperCallbacks::Helpers.deep_merge_hashes_and_combine_arrays(
        all_ancestral_after_callbacks,
        singleton_class_after_callbacks
      )

      all_after_callbacks_on_method = all_after_callbacks[method_name] || []

      all_after_callbacks_on_method.each do |after_callback, options_if|
        is_condition_truthy = true

        if options_if
          is_condition_truthy = instance_exec *args, &options_if
        end

        if is_condition_truthy
          if after_callback.is_a? Proc
            instance_exec *args, &after_callback
          else
            send after_callback
          end
        end
      end
    end

    private

    def callbacks_prepended_module_instance
      _callbacks_prepended_module_instance = self.singleton_class.ancestors.reverse.detect { |ancestor| ancestor.is_a? SuperCallbacks::Prepended }

      if _callbacks_prepended_module_instance.nil?
        self.singleton_class.prepend SuperCallbacks::Prepended
        _callbacks_prepended_module_instance = self.singleton_class.ancestors.reverse.detect { |ancestor| ancestor.is_a? SuperCallbacks::Prepended }
      end

      _callbacks_prepended_module_instance
    end
  end
end
