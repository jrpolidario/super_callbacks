# This is the module that will be prepended to the base (target) class where `include SuperCallbacks`
# have been called. This will be always a new instance of a Module, and will not be a permanent
# Module. This is important because, this module-instance is used by SuperCallbacks to define
# the methods whenever `before` or `after` is called. These defined methods here will then have a
# `super` inside it, which then will also call the "real" method defined in the target class.
module SuperCallbacks
  class Prepended < Module
    attr_accessor :base

    def initialize(base)
      @base = base
    end
  end
end
