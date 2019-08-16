module SuperCallbacks
  # The methods defined here will be available "class" and "instance" for any class where SuperCallbacks is included
  module ClassAndInstanceMethods
    def before!(method_name, *remaining_args, &callback_proc)
      raise ArgumentError, "`#{method_name}` is not or not yet defined for #{self}" unless method_defined? method_name
      before(method_name, *remaining_args, &callback_proc)
    end

    def after!(method_name, *remaining_args, &callback_proc)
      raise ArgumentError, "`#{method_name}` is not or not yet defined for #{self}" unless method_defined? method_name
      after(method_name, *remaining_args, &callback_proc)
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
    end

    def instance_variables_before_change
      raise 'You cannot call this method outside the SuperCallbacks cycle' if Thread.current[:super_callbacks_all_instance_variables_before_change].nil?
      Thread.current[:super_callbacks_all_instance_variables_before_change][object_id].last
    end

    def instance_variable_before_change(instance_variable)
      raise 'You cannot call this method outside the SuperCallbacks cycle' if Thread.current[:super_callbacks_all_instance_variables_before_change].nil?
      raise ArgumentError, "#{instance_variable} should be a string that starts with `@`" unless instance_variable.to_s.start_with? '@'
      instance_variables_before_change[instance_variable.to_sym]
    end

    def instance_variable_changed?(instance_variable)
      raise 'You cannot call this method outside the SuperCallbacks cycle' if Thread.current[:super_callbacks_all_instance_variables_before_change].nil?
      raise ArgumentError, "#{instance_variable} should be a string that starts with `@`" unless instance_variable.to_s.start_with? '@'

      before_change_value = instance_variable_before_change(instance_variable.to_sym)
      current_value = instance_variable_get(instance_variable)
      before_change_value != current_value
    end

    # TODO
    # def around
    # end
  end
end
