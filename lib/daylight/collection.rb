##
# Alternate collection methods for +first_or_create+, +first_or_initialize+.
#
# Used to split the +original_params+ into known attributes and query params
# added by ResourceProxy.
#
# Parameters not added by ResourceProxy will still be merged into the supplied
# attributes.  This is the current ActiveResource behavior.
#
# Parameters that contain known attributes (ie. +:filter+) will also be merged
# with the supplied attributes.  The query parameters (ie. +:scopes+) will be
# set on +prefix_options+
#
# For example:
#
#    users = User.find(:all, params: {
#      filters: {last_name: {'Bonzai'}},
#      scopes: ['planet_ten'],
#      band: 'Hong Kong Cavaliers'
#    })
#
# Return all Users in the band 'Hong Kong Cavaliers' where their last name
# is 'Bonzai'.  If a User with first name 'Buckaroo' does not exist:
#
#    users.first_or_create(first_name: 'Buckaroo')
#
# Or:
#
#    users.first_or_initialize(first_name: 'Buckaroo').save
#
# Will issue the following request where the band is kept as a query parameter
# and the contents of the +filter+ paramter are merged with the attributes:
#
#    POST: /api/v1/users.json?scopes[]=planet_ten
#    DATA: {"user":{"first_name":"Buckaroo", "last_name":"Bonzai", "band":"Hong Kong Cavaliers"}}
#
# See:
# ActiveResource::Collection
module Daylight::Collection
  extend ActiveSupport::Concern

  included do
    attr_reader :metadata

    ##
    # Overwriting ActiveResource::Collection#initialize
    #---
    # Concern cannot call `super` from module to base class (we think)
    def initialize(elements = [])
      if Hash === elements && elements.has_key?('meta')
        metadata = (elements.delete('meta')||{}).with_indifferent_access  # save and strip any metadata supplied in the response
        elements = ActiveResource::Formats.remove_root(elements)          # re-evaluate removing root since we've removed a key
      end

      @metadata = metadata || {}
      @elements = elements.each {|e| e['meta'] = @metadata }              # pass metadata down to resource records
    end

    ##
    # Any attribute metadata about how the collection was obtained that is used
    # when creating a new element in that collection.
    #
    # See
    # #first_or_create
    # #first_or_initialize
    def where_values
      metadata[:where_values] || {}
    end

    ##
    # Alternate +first_or_create+ which removes all ResourceProxy parameters,
    # merging +known_attributes+ and setting +query_params+ on +prefix_options+
    #
    # All other pararmeters are handled identically to the original method.
    #
    # See:
    # ActiveResource::Collection#first_or_create
    def first_or_create attributes={}
      first || create_resource(attributes.reverse_merge(where_values))
    rescue NoMethodError
      raise "Cannot build resource from resource type: #{resource_class.inspect}"
    end

    ##
    # Alternate +first_or_initialize+ which removes all ResourceProxy parameters,
    # merging +known_attributes+ and setting +query_params+ on +prefix_options+
    #
    # All other pararmeters are handled identically to the original method.
    #
    # See:
    # ActiveResource::Collection#first_or_initialize
    def first_or_initialize attributes={}
      first || initialize_resource(attributes.reverse_merge(where_values))
    rescue NoMethodError
      raise "Cannot create resource from resource type: #{resource_class.inspect}"
    end

    protected
      ##
      # Performs the work of merging known attributes to the supplied attributes
      # on the resource, setting the +prefix_options+ to the known params, attempting
      # to save, and returning the resource.
      def create_resource attributes={}
        resource_class.new(attributes.update(known_attributes)).tap do |resource|
          resource.prefix_options = query_params
          resource.save
        end
      end

      ##
      # Performs the work of merging known attributes to the supplied +attributes+
      # on the resource, setting the +prefix_options+ to the known params and and
      # returning the initialized resource.
      def initialize_resource attributes={}
        resource_class.new(attributes.update(known_attributes)).tap do |resource|
          resource.prefix_options = query_params
        end
      end

    private
      # Parameter values to be merged with supplied attributes
      KNOWN_PARAMETER_KEYS = [:filters].freeze

      # Parameters to continue to use as query parameters
      QUERY_PARAMETER_KEYS = [:scopes].freeze

      # Additional collection-based parameters to strip/ignore
      STRIP_PARAMETER_KEYS = [:order, :limit, :offset].freeze

      # All parameters that are used by ResourceProxy that should be removed from attributes
      PROXY_PARAMETER_KEYS = KNOWN_PARAMETER_KEYS + QUERY_PARAMETER_KEYS + STRIP_PARAMETER_KEYS

      ##
      # Helper to strip all params used by ResourceProxy from +orignal_params+
      def clean_params
        original_params.except(*PROXY_PARAMETER_KEYS)
      end

      # Helper to extract query params that will be used as +prefix_option+
      def query_params
        original_params.slice(*QUERY_PARAMETER_KEYS.inject(&:update)) || {}
      end

      # Helper to extract known params that will be used as known attributes
      def known_params
        original_params.values_at(*KNOWN_PARAMETER_KEYS).inject(&:update) || {}
      end

      # Helper to get additional known attributes from +original_params+
      def known_attributes
        clean_params.update(known_params)
      end
  end

end

##
# Hook into ActiveResource::Collection to override their methods
ActiveResource::Collection.class_eval do
  include Daylight::Collection
end
