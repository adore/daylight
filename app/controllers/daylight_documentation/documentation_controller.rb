##
# Controller that handles rendering the API Documentation
class DaylightDocumentation::DocumentationController < ActionController::Base
  layout 'documentation'

  caches_page :index, :model

  ##
  # Index of all the models/endpoints
  def index
    @models = models
  end

  ##
  # Model description
  def model
    @model  = find_model
    @schema = model_schema
  end

  ##
  # Schema
  def schema
    render json: model_schema, content_type: 'application/schema+json'
  end

  private

    def models
      Rails.application.eager_load!
      ActiveRecord::Base.descendants
    end

    def find_model
      model_name = params[:model]
      models.find { |model| model.name.underscore == model_name }
    end

    def model_schema
      find_model.new.active_model_serializer.schema
    end

end
