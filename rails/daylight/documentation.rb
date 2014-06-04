require 'haml'

##
# Rails::Engine to add Documentation features to a Daylight::Server
module Daylight
  class Documentation < ::Rails::Engine
    config.autoload_paths << File.expand_path("../..", __FILE__)

    isolate_namespace Daylight
  end
end
