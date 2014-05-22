$:.unshift File.expand_path('../lib')
$:.unshift File.expand_path('../rails/extensions')

# Simplecov must be loaded before environment
require File.expand_path('spec/config/simplecov_rcov')

require 'daylight'
require 'daylight/mock'

require 'rspec/autorun'

Daylight::API.setup! password: 'test', endpoint: 'http://bluesky.test', version: 'v1'

RSpec.configure do |config|
  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  # clean up after every test
  config.after(:each) do
    FakeWeb.clean_registry
  end
end
