ENV["RAILS_ENV"] ||= 'test'

$:.unshift File.expand_path('../../client', __FILE__)

# load the rails environment
require File.expand_path("../../config/environment.rb",  __FILE__)

require 'rspec/rails'
require 'rspec/autorun'

require 'daylight/api'
require 'api'

Daylight::API.setup! endpoint: 'http://daylight.test', version: 'v1'

# Hand off web request to the rack application
# This allows us to test end-to-end without running a webserver
require 'artifice'
Artifice.activate_with(DaylightExample::Application)

RSpec.configure do |config|
  config.use_transactional_fixtures = true

  config.order = "random"
end

load "#{Rails.root.to_s}/db/schema.rb"
