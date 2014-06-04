# Rails extensions, patches, fixes needed to execute a Daylight::Server
require 'extensions/array_ext'
require 'extensions/autosave_association_fix'
require 'extensions/has_one_serializer_ext'
require 'extensions/nested_attributes_ext'
require 'extensions/read_only_attributes'
require 'extensions/render_json_meta'
require 'extensions/route_options'

##
# Include into Rails server to handle Daylight::API queries
module Daylight
  extend ActiveSupport::Autoload

  autoload :Helpers
  autoload :Params
  autoload :Refiners
end
