# Rails extensions, patches, fixes needed to execute a Daylight::Server
# In the future, these could be configurable or contributed back

require 'extensions/array_ext'                  # non-destructive `extract_options`
require 'extensions/autosave_association_fix'   # fix for autosaving `inverse_of` associations
require 'extensions/has_one_serializer_ext'     # serializer recognizes belong_to :through association
require 'extensions/nested_attributes_ext'      # associates two previously existing records
require 'extensions/read_only_attributes'       # serializer support for `read_only` attributes
require 'extensions/render_json_meta'           # adds metadata to the json response
require 'extensions/route_options'              # adds associated, remoted options to routes

##
# Include into Rails server to handle Daylight::API queries
module Daylight
  extend ActiveSupport::Autoload

  autoload :Helpers
  autoload :Params
  autoload :Refiners
end
