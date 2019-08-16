module SuperCallbacks
  # The methods defined here will be available "class" methods for any class where SuperCallbacks is included
  module ClassMethods
    private

    def callbacks_prepended_module_instance
      ancestors.reverse.detect { |ancestor| ancestor.is_a? SuperCallbacks::Prepended }
    end
  end
end
