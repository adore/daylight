##
# Daylight API Client Library
#
# Use this client in your Ruby/Rails applications for ease of use access to the Daylight API.
#
# Unlike typical ActiveResource clients, the Daylight API Client has been designed to be used similarly to ActiveRecord with scopes and the ability to chain queries.
#
#     Daylight::Zone.all
#     Daylight::Zone.where(code:'iad1')
#     Daylight::Zone.internal # scope
#     Daylight::Zone.find(1).tenants # associations
#
class Daylight::API < ActiveResource::Base
  include Daylight::Refinements
  include Daylight::Associations

  class << self
    attr_reader    :version
    cattr_accessor :request_root_in_json
    alias_method   :endpoint, :site

    SUPPORTED_VERSIONS = %w[v1].freeze
    DEFAULT_CONFIG = {
      endpoint: 'http://localhost',
      version:  SUPPORTED_VERSIONS.last
    }.freeze

    ##
    # Setup and configure the Daylight API. Must be called before use.
    def setup! options={}
      config = options.with_indifferent_access.reverse_merge(DEFAULT_CONFIG)

      self.password = config[:password]
      self.endpoint = config[:endpoint]
      self.version  = config[:version]
      self.timeout  = config[:timeout] if config[:timeout] # default read_timeout is 60

      # API requires JSON request to emit a root node named after the object’s type
      # this is different from `include_root_in_json` where every ActiveResource
      # supplies its root.
      self.request_root_in_json = config[:request_root_in_json] || true

      headers['X-Daylight-Client'] = Daylight::VERSION

      # alias_apis
    end

    ##
    # Find a single resource from the default URL
    # Fixes bug to short-circuit and return nil if scope/id is nil.
    def find_single(scope, options)
      return if scope.nil?
      super
    end

    ##
    # Whether to show root for the request
    def request_root_in_json?
      request_root_in_json && format.extension == 'json'
    end

    private
      alias_method :endpoint=, :site=

      ##
      # Set the version and make sure it's appropiate
      def version= v
        unless SUPPORTED_VERSIONS.include?(v)
          raise "Unsupported version #{v} is not one of #{SUPPORTED_VERSIONS.join(', ')}"
        end

        @version     = v.upcase
        version_path = "/#{v.downcase}/".gsub(/\/+/, '/')

        set_prefix version_path
      end

      ##
      # Alias the configured version APIs to be references without a version number
      # Daylight::V1::Zone => Daylight::Zone
      def alias_apis
        api_classes.each do |api|
          Daylight.const_set(api, "Daylight::#{version}::#{api}".constantize)
        end

        true
      end

      ##
      # Load and return the APIs for the configured version
      def api_classes
        api_files = File.join(File.dirname(__FILE__), version.downcase, "**/*.rb")

        Dir[api_files].each { |filename| load filename }

        "Daylight::#{version}".constantize.constants
      end
  end

  attr_reader :metadata

  ##
  # Overwriting ActiveResource::Base#initialize
  #---
  # Concern cannot call `super` from module to base class (we think)
  def initialize(attributes={}, persisted = false)
    if Hash === attributes && attributes.has_key?('meta')
      metadata = (attributes.delete('meta')||{}).with_indifferent_access  # save and strip any metadata supplied in the response
    end
    @metadata = metadata || {}

    super
  end

  ##
  # Get the list of read_only attributes.
  # If there are none then an empty array is supplied.
  def read_only
    @read_only ||= begin
      metadata[:read_only][self.class.element_name] || []
    rescue
      []
    end
  end

  class HashResourcePassthrough
    def self.new(value, _)
      # load values using ActiveResource::Base and extract them as attributes
      Daylight::API.new(value.duplicable? ? value.dup : value).attributes
    end
  end

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

  ##
  # Adds API specific options when generating json
  #
  # See
  # except_read_only
  def as_json(options={})
    super(except_read_only(options))
  end

  ##
  # Adds API specific options when generating xml
  #
  # See
  # except_read_only
  def to_xml(options={})
    super(except_read_only(options))
  end

  ##
  # Writers for read only attributes are not included as methods
  def respond_to?(method_name, include_priv = false)
    return false if read_only?(method_name)
    super
  end

  private
    def method_missing(method_name, *arguments)
      if read_only?(method_name)
        logger.warn "Cannot set read_only attribute: #{method_name[0...-1]}" if logger
        raise NoMethodError, "Cannot set read_only attribute: #{method_name[0...-1]}"
      end

      super
    end

    ##
    # Ensures that read_only attributes are merged in with :except options.
    def except_read_only options
      options.merge(except: (options[:except]||[]).push(*read_only))
    end

    ##
    # Determines if `method_name` is writing to a read only attribute.
    def read_only? method_name
      !!(method_name =~ /(?:=)$/ && read_only.include?($`))
    end
end

