require 'rake'
require 'rails/tasks'
require 'rdoc/task'

namespace :doc do
  namespace :api do

    desc 'Pre-generate the API documentation'
    task generate: %w[environment doc:api:clean] do
      require 'artifice'
      require 'open-uri'

      Artifice.activate_with(Rails.application.class)

      Rails.application.eager_load!
      helpers = Daylight::Documentation.routes.url_helpers
      models = ActiveRecord::Base.descendants
      open helpers.index_url(host: 'localhost')
      models.each do |model|
        open helpers.model_url(model.name.underscore, host: 'localhost')
      end
    end

    desc 'Clear the API documentation'
    task clean: %w[environment] do
      helpers = Daylight::Documentation.routes.url_helpers
      path = helpers.index_path

      # remove the index
      FileUtils.rm_rf File.join(Rails.root, 'public', path.sub(%r{/$}, '.html'))

      # and the files
      FileUtils.rm_rf File.join(Rails.root, 'public', path)
    end

  end
end
