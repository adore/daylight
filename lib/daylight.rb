$:.unshift File.expand_path('../../rails', __FILE__)

require 'active_support/core_ext'
require 'active_resource'

##
# Include into API client to enable Daylight::API based queries

module Daylight
  extend ActiveSupport::Autoload

  eager_autoload do
    autoload :Version

    autoload :Associations
    autoload :AssociationPersistance
    autoload :Collection
    autoload :Errors
    autoload :Inflections
    autoload :Refinements
    autoload :ReadOnly
    autoload :ReflectionExt
    autoload :RequestId
    autoload :ResourceProxy

    autoload :API
  end
end

# run eager load
Daylight.eager_load!
