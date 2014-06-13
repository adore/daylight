##
# Daylight API Client Library
#
# Use this client in your Ruby/Rails applications for ease of use access to the
# Client API.
#
# Unlike typical ActiveResource clients, the Daylight API Client has been
# designed to be used similarly to ActiveRecord with scopes and the ability to
# chain queries.
#
#     ClientAPI::Post.all
#     ClientAPI::Post.where(code:'iad1')
#     ClientAPI::Post.internal                    # scope
#     ClientAPI::Post.find(1).comments            # associations
#     ClientAPI::Post.find(1).public_commenters   # remote collection
#     ClientAPI::Post.find(1).commenters.
#       where(username: 'reidmix')                # chaining
#
# Build your client models using Daylight::API, it is a wrapper with extended
# functionality to ActiveResource::Base
#
#     class ClientAPI::Post < Daylight::API
#       scopes :internal
#
#       belongs_to :user
#       has_many   :comments
#       has_many   :commenters, through: :comments
#
#       remote :public_commenters, class_name: 'client_api/user'
#     end
#
# Once all your client models are built, setup your API Client Library and
# startup via `setup!` (in an intitializer):
#
#     require 'client_api'
#
#     Daylight::API.setup!({
#       namespace: 'client_api',
#       password:  'test',
#       endpoint:  'http://api.example.org/
#     })

class Daylight::API < ActiveResource::Base
  include Daylight::ReadOnly
  include Daylight::Refinements
  include Daylight::Associations

  class << self
    attr_reader    :version, :versions, :namespace
    cattr_accessor :request_root_in_json
    alias_method   :endpoint, :site

    DEFAULT_CONFIG = {
      namespace: 'API',
      endpoint:  'http://localhost',
      versions:  %w[v1],
    }.freeze

    ##
    # Setup and configure the Daylight API. Must be called before Client API use.
    # Will use the following defaults:
    #
    #     Daylight::API.setup!({
    #       namespace: 'API',
    #       password:  nil,
    #       endpoint:  'http://localhost',
    #       versions:  ['v1'],
    #       version:   'v1'
    #       timeout:   60  # in seconds
    #     })
    #
    # Daylight currenly requires that your API is within a module `namespace`
    #
    # The `endpoint` sets ActiveResource#site configuration.
    # The `password` is the HTTP Authentication password.
    #
    # Daylight assumes you're versioning your API, you can supply the `versions`
    # that are supported by your API and which `version` is active.
    #
    # By default, ActiveResource#request_root_in_json is set to true.
    # You can turn this off with the `request_root_in_json` configuration.
    #
    # A convenience for versioned APIs is to alias the active Client API models
    # to versionless constance.  For example
    #
    #     ClientAPI::V1::Post
    #
    # Aliased to:
    #
    #     ClientAPI::Post
    #
    # This functionalitity is turned on using the `alias_apis` configuration.

    def setup! options={}
      config = options.with_indifferent_access.reverse_merge(DEFAULT_CONFIG)

      self.namespace = config[:namespace]
      self.password  = config[:password]
      self.endpoint  = config[:endpoint]
      self.versions  = config[:versions].freeze
      self.version   = config[:version] || config[:versions].last  # specify or use most recent version
      self.timeout   = config[:timeout] if config[:timeout]        # default read_timeout is 60

      # API requires JSON request to emit a root node named after the object’s type
      # this is different from `include_root_in_json` where every ActiveResource
      # supplies its root.
      self.request_root_in_json = config[:request_root_in_json] || true

      headers['X-Daylight-Framework'] = Daylight::VERSION

      # alias_apis if config[:alias_apis]
    end

    ##
    # Find a single resource from the default URL
    #
    # Fixes bug to short-circuit and return `nil` if scope/id is nil.
    # ActiveResource::Base will perform the call and return with an error.

    def find_single(scope, options)
      return if scope.nil?
      super
    end

    ##
    # Whether to show root for the request
    #
    # Turned on by default when transmitting JSON requests.

    def request_root_in_json?
      request_root_in_json && format.extension == 'json'
    end

    private
      attr_writer  :versions, :namespace
      alias_method :endpoint=, :site=

      ##
      # Set the `version` and make sure it's a member of the supported versions

      def version= v
        unless versions.include?(v)
          raise "Unsupported version #{v} is not one of #{versions.join(', ')}"
        end

        @version     = v.upcase
        version_path = "/#{v.downcase}/".gsub(/\/+/, '/')

        set_prefix version_path
      end

      ##
      # Alias the configured Client API constants to be references without a
      # version number for the active version:
      #
      # For example, if the active version is 'v1':
      #
      #     ClientAPI::Zone   # => Daylight::V1::Zone

      def alias_apis
        api_classes.each do |api|
          Daylight.const_set(api, "#{namespace}::#{version}::#{api}".constantize)
        end

        true
      end

      ##
      # Load and return the Client APIs for the configured version.
      #
      # Searches in the `lib` directory of the Client API under the namespace
      # and version.  By default, searches Client models in 'lib/api/v1' and
      # loads them.

      def api_classes
        api_files = File.join(File.dirname(__FILE__), version.downcase, "**/*.rb")

        Dir[api_files].each { |filename| load filename }

        "#{namespace}::#{version}".constantize.constants
      end
  end

  attr_reader :metadata

  ##
  # Extends ActiveResource to allow for saving metadata from the responses on
  # the `meta` key.  Will store this metadata on the `metadata` attribute.
  #---
  # Does this extension by overwritting ActiveResource::Base#initialize method
  # Concern cannot call `super` from module to base class (we think)

  def initialize(attributes={}, persisted = false)
    if Hash === attributes && attributes.has_key?('meta')
      # save and strip any metadata supplied in the response
      metadata = (attributes.delete('meta')||{}).with_indifferent_access
    end
    @metadata = metadata || {}

    super
  end

  ##
  # Used to assist `find_or_create_resource_for` to use embedded attributes
  # to new Daylight::API model objects.
  #
  # See:
  # find_or_create_resource_for

  class HashResourcePassthrough
    def self.new(value, _)
      # load values using ActiveResource::Base and extract them as attributes
      Daylight::API.new(value.duplicable? ? value.dup : value).attributes
    end
  end

  ##
  # When an association is supplied via a hash of `*_attributes` then create
  # (a set) of new Client API objects instead of leaving as a hash.

  def find_or_create_resource_for name
    # if the key is attributes attributes for a configured association
    if /(?:_attributes)\z/ =~ name && reflections.key?($`.to_sym)
      HashResourcePassthrough
    else
      super
    end
  end

  ##
  # Returns the serialized string representation of the resource in the configured
  # serialization format specified in ActiveResource::Base.format.
  #
  # For JSON formatted requests default option is to include the root element
  # depending on the `request_root_in_json` configuration.

  def encode(options={})
    super(self.class.request_root_in_json? ? { :root => self.class.element_name }.merge(options) : options)
  end
end

