require 'rack'

##
# Simple mocking framework that simplifies the process of writing tests for code that uses the Daylight client library.
#
# Works with both Rspec and TestUnit/Minitest.
#
# To start add this to your test_helper.rb or spec_helper.rb:
#
#     Daylight::Mock.setup
#
# The mock will simulate responses to calls so you don't have to stub out anything, especially not the HTTP calls themselves.
# At the end of the test you can examine the calls that were made by calling *daylight_mock*.
#
# For example, this call returns a list of all the updated calls made on a *Host* object:
#
#     daylight_mock.updated(:host)
#
# To get only the last request use:
#
#     daylight_mock.last_updated(:host)
#
# Supported Calls: *created, updated, associated, indexed, shown, deleted*
#
module Daylight
  module Mock

    ##
    # Represents a single mocked request-response pair.
    class Handler
      PathParts = Struct.new(:version, :resource, :id, :associated)
      PATH_PARTS_REGEX = %r{^/([^/]+)/([^/]+)(?:/(\d+))?(?:/([^/]+))?\.json$}

      attr_reader :request, :status, :response, :target_object

      delegate :resource, to: :path_parts

      def initialize(request)
        @request = request
      end

      ##
      # The request path split into logical parts: version, resource, id, and assocatied.
      #
      # Returns a PathParts Struct
      def path_parts
        @path_parts ||= PathParts.new(*path.match(PATH_PARTS_REGEX).captures)
      end

      ##
      # The request's path
      def path
        request.uri.path
      end

      ##
      # The mock respose body
      def response_body
        @response_body ||= handle_request
      end

      ##
      # The request's POST data
      def post_data
        @post_data ||= JSON.parse(request.body)
      end

      ##
      # The request's query params
      def params
        @params ||= Rack::Utils.parse_nested_query(request.uri.query)
      end

      ##
      # The action to perform (based on the request path and method).
      #
      # Returns :associated, :shown, :indexed, :created, :updated or :deleted
      def action
        @action ||=
          case request.method
          when :get
            if path_parts.associated.present?
              :associated
            elsif path_parts.id.present?
              :shown
            else
              :indexed
            end
          when :post
            :created
          when :put
            :updated
          when :delete
            :deleted
          end
      end

      private
        def model_class(model_name)
          model_name.classify.constantize
        end

        def handle_request
          send "process_#{action}"
        end

        def process_indexed
          clazz = model_class(path_parts.resource)
          list = [new_record(clazz)] * (rand(4)+1)

          respond_with(body: list)
        end

        def process_shown
          clazz = model_class(path_parts.resource)
          @target_object = new_record(clazz, id: path_parts.id.to_i)

          respond_with(body: @target_object)
        end

        def process_associated
          clazz = model_class(path_parts.associated)
          list = [new_record(clazz)] * (rand(4)+1)

          respond_with(body: list)
        end

        def process_created
          data = post_data[path_parts.resource.singularize]
          clazz = model_class(path_parts.resource)
          @target_object = new_record(clazz, data.merge(id:rand(100) + 1))

          respond_with(body: @target_object, status: 201)
        end

        def process_updated
          clazz = model_class(path_parts.resource)
          data = post_data[path_parts.resource.singularize]
          @target_object = new_record(clazz, data.merge(id: path_parts.id.to_i))

          respond_with(status: 201)
        end

        def process_deleted
          clazz = model_class(path_parts.resource)
          @target_object = new_record(clazz, id: path_parts.id.to_i)

          respond_with(status: 200)
        end

        def respond_with(options={})
          @response = options[:body]
          options[:body]   &&= encode(options[:body])
          options[:status] ||= 200
          @status = options[:status]
          options
        end

        def encode(response)
          if @response.is_a? Enumerable
            {'foo'=>@response}.to_json
          else
            @response.encode
          end
        end

        def new_record(clazz, options={})
          filters = params['filters'] || {}
          clazz.new(options.reverse_merge(filters).reverse_merge(id: rand(100) + 1))
        end
    end

    ##
    # Keeps track of all request and response pairs.
    # Stored by action and resource.
    #
    # Example:
    #
    #     daylight_mock.created(:project).count.should == 3
    #
    #     daylight_mock.last_created(:project).name.should == 'Test Project'
    class Recorder
      def initialize
        # hashy hash hash
        @storage = Hash.new do |action_hash, action|
          action_hash[action] =
            Hash.new do |handler_hash, handler|
              handler_hash[handler] = []
            end
        end
      end

      %w[created updated associated indexed shown deleted].each do |action|
        define_method action do |resource|
          @storage[action.to_s][resource.to_s.pluralize]
        end

        define_method "last_#{action}" do |resource|
          @storage[action.to_s][resource.to_s.pluralize].last
        end
      end

      ##
      # Store a Handler in the Recorder
      def record(handler)
        @storage[handler.action.to_s][handler.resource.to_s] << handler
      end
    end

    ##
    # Minitest hook
    module Minitest
      # for minitest
      def before_setup
        capture_api_requests
      end
    end

    class << self

      ##
      # Run in the test framework's setup to start and configure Daylight::Mock.
      #
      #     Daylight::Mock.setup
      def setup
        setup_rspec    if Module.const_defined? "RSpec"
        setup_minitest if Module.qualified_const_defined?("MiniTest::Spec")
      end

      private
        def setup_rspec
          require 'webmock/rspec'

          RSpec.configure do |config|
            config.include Daylight::Mock

            config.before(:each) do
              capture_api_requests
            end
          end
        end

        def setup_minitest
          require 'webmock/minitest'

          clazz = MiniTest::Test rescue MiniTest::Unit::TestCase

          clazz.class_eval do
            include Daylight::Mock
            include Daylight::Mock::Minitest
          end
        end
    end

    ##
    # Access to Daylight::Mock::Recorder from within test definitions.
    def daylight_mock
      @daylight_mock ||= Recorder.new
    end

    private
      def capture_api_requests
        # capture all requests to the API server
        stub_request(:any, /#{site_with_credentials}/)
          .with(headers: {'X-Daylight-Framework' => /.*/})
          .to_return do |request|
            handler = Handler.new(request)
            daylight_mock.record(handler)
            handler.response_body
          end
      end

      # Webmock prepends urls with any username and password when
      # it does matching.
      def site_with_credentials
        @site_with_credentials ||= Daylight::API.site.dup.tap do |site|
          site.userinfo = "#{Daylight::API.user}:#{Daylight::API.password}"
          site.to_s
        end
      end
  end
end
