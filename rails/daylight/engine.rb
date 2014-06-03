module Daylight
  class Engine < ::Rails::Engine
    config.autoload_paths << File.expand_path("../../app", __FILE__)

    isolate_namespace Daylight
  end
end
