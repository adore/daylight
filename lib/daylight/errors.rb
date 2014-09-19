module Daylight::Errors
  extend ActiveSupport::Concern

  ##
  # Regex for Content-Type
  #--
  # http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html
  CONTENT_TYPE_FORMAT = /([^\/]+)\/([^;]+)(?:;.*)?/

  included do
    ##
    # Error messages from the root cause
    # :attr: messages
    attr_reader :messages, :request_id

    ##
    # Parses the messages from the response
    def initialize response, message = nil
      super
      @messages = []
      parse(response)
    end

    ##
    # Attaches the root cause messaging to included Client message
    def to_s
      super.tap do |message|
        message << "  Root Cause = #{messages.join(', ')}." if messages?
        message << "  Request-Id = #{request_id}." if request_id
      end
    end

    def messages?
      messages.present?
    end

    private
      ##
      # Sets the error messages when there is a payload on the response and a format that is handled
      # Saves the request_id of the error if available.
      #--
      # "application/xml; charset=utf-8"
      # "application/json; charset=utf-8"
      def parse response
        @request_id = response.header['x-request-id']

        _, subtype = CONTENT_TYPE_FORMAT.match(response.header['content-type']).captures rescue nil
        return unless subtype.present? && response.body.present?

        @messages =
          case subtype
            when  'xml'; self.class.from_xml(response.body)
            when 'json'; self.class.from_json(response.body)
            else
              []
          end
      end
  end

  module ClassMethods
    ##
    # Parse payload that is in JSON
    #--
    # Examples:
    #
    # {'errors':'this is the problem'}
    # {'errors':['this is problem one','this is problem two']}
    def from_json(json)
      decoded = ActiveSupport::JSON.decode(json) || {} rescue {}
      if decoded.kind_of?(Hash) && decoded.has_key?('errors')
        Array.wrap(decoded['errors'])
      else
        []
      end
    end

    ##
    # Parse payload that is in XML
    #--
    # Examples:
    # <errors>
    #   <error>this is a Problem<error>
    # </errors>
    # <errors>
    #   <error>this is problem one<error>
    #   <error>this is problem one<error>
    # </errors>
    def from_xml(xml)
      Array.wrap(Hash.from_xml(xml)['errors']['error']) rescue []
    end
  end
end

##
# Hook into ActiveResource::ClientError to parse the payload
ActiveResource::ClientError.class_eval do
  include Daylight::Errors
end
