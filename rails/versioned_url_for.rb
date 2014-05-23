module VersionedUrlFor
  extend ActiveSupport::Concern

  included do
    def url_for options={}
      super(options.respond_to?(:to_model) ? versioned_url_for(options) : options)
    end

    protected
      def versioned_url_for model
        send(versioned_path, model)
      end

      def versioned_path
        "#{versioned_name}_path"
      end

      def versioned_name
        controller_path.gsub('/', '_').singularize
      end
  end
end