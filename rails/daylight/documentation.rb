require 'haml'
require 'actionpack/page_caching'

module DaylightDocumentation
end

##
# Rails::Engine to add Documentation features to a Daylight::Server
module Daylight
  class Documentation < ::Rails::Engine
    isolate_namespace DaylightDocumentation

    class << self
      attr_accessor :version, :namespace
    end

    self.version   = Daylight::API.version   || 'v1'
    self.namespace = Daylight::API.namespace || 'API'
  end
end
