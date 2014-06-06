require 'haml'
require 'actionpack/page_caching'

module DaylightDocumentation
end

##
# Rails::Engine to add Documentation features to a Daylight::Server
module Daylight
  class Documentation < ::Rails::Engine
    isolate_namespace DaylightDocumentation
  end
end
