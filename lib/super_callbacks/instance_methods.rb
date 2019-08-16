module SuperCallbacks
  # The methods defined here will be available "class" methods for any class where SuperCallbacks is included
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
