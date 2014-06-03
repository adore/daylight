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

require 'daylight/engine'

require 'daylight/helpers'
require 'daylight/params'
require 'daylight/refiners'

require 'extensions/array_ext'
require 'extensions/autosave_association_fix'
require 'extensions/has_one_serializer_ext'
require 'extensions/nested_attributes_ext'
require 'extensions/read_only_attributes'
require 'extensions/render_json_meta'
require 'extensions/route_options'

module Daylight
end
