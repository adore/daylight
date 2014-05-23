##
# Mixin to simulate access to params (from Helpers) outside of ActiveController context
module Params
  extend ActiveSupport::Concern

  class HelperProxy
    include Helpers

    attr_accessor :params

    def initialize params
      @params = params
    end
  end

  included do
    ##
    # Creates +params+ method and yields to block, undefine the param method
    def with_helper params
      yield HelperProxy.new(params)
    end
  end
end