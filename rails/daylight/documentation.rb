require 'haml'
require 'actionpack/page_caching'

##
# Rails::Engine to add Documentation features to a Daylight::Server
module Daylight
  class Documentation < ::Rails::Engine
    isolate_namespace Daylight::Documentation
  end
end
