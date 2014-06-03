$: << File.expand_path('../../rails', __FILE__)

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
end
