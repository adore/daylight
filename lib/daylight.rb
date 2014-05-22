require 'active_support/core_ext'
require 'active_resource'

require 'daylight/version'
require 'daylight/errors'
require 'daylight/associations'
require 'daylight/collection'
require 'daylight/inflections'
require 'daylight/refinements'
require 'daylight/resource_proxy'
require 'daylight/api'

module Daylight

  def self.install_rails_extensions
    Dir[File.expand_path('../../rails/**/*.rb', __FILE__)].each {|file| require file }
  end

end
