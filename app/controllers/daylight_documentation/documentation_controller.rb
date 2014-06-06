##
# Controller that handles rendering the API Documentation
class DaylightDocumentation::DocumentationController < ActionController::Base
  layout 'documentation'

  caches_page :index, :model_index, :model

  ##
  # Index
  def index
  end

  ##
  # Index of all the models/endpoints
  def model_index
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
    # make sure all the models are loaded
    Dir[Rails.root + 'app/models/**/*.rb'].each {|f| require f }
    ActiveRecord::Base.descendants
  end
end
