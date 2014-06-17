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
    model_name = params[:model]
    @model = models.find { |model| model.name.underscore == model_name }
  end

  private

  def models
    Rails.application.eager_load!
    ActiveRecord::Base.descendants
  end
end
