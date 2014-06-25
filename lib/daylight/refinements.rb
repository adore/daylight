##
# Support for handling ActiveRecord-like refinementmes and chaining them together
# These refinements include: +where+, +find_by+, +order+, +limit+, and +offset+
# Named +scopes+ are also supported.
module Daylight::Refinements
  extend ActiveSupport::Concern

  module ClassMethods
    delegate :where, :find_by, :order, :limit, :offset, to: :resource_proxy

    attr_accessor :scope_names

    # Define scopes that the class can be refined by
    def scopes *scope_names
      self.scope_names = scope_names
      self.scope_names.freeze

      scope_names.each do |scope|
        # hand chaining duties off to the ResourceProxy instance
        define_singleton_method scope do
          resource_proxy.append_scope(scope)
        end

        # ResourceProxy instance also needs to respond to scopes
        resource_proxy_class.send(:define_method, scope) do
          append_scope(scope)
        end
      end
    end

    ##
    # Use limits if no argument are supplied.  Otherwise, continue to use
    # the ActiveRecord version which retrieves the full result set and calls
    # first.
    #
    # See:
    # ActiveRecord::Base#first
    # Daylight::ResourceProxy#first
    def first *args
      args.size.zero? ? resource_proxy.first : super
    end

    protected
      # Ensure the subclasses are setup with their ResourceProxy
      def inherited subclass
        Daylight::ResourceProxy[subclass]
      end

    private
      # Sets up and saves the ResourceProxy in the resource class
      def resource_proxy_class
        Daylight::ResourceProxy[self]
      end

      # All chains create a new instance of the ResourceProxy
      def resource_proxy
        resource_proxy_class.new
      end
  end
end
