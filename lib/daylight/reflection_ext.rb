require 'active_resource/reflection'

##
# Extension to use the API namespace and version modules to lookup classes for
# a reflection.  The benefit is to be able to define an association wihtout
# the module name or using the :class_name option.
#
# Without the extension, we have to specify the `:class_name`:
#
#    class API::V1::Post < Daylight::API
#       has_many :comments, class_name: 'api/v1/comment'
#    end
#
# With the extension, it will be determined using the namespace and version modules
#
#    class API::V1::Post < Daylight::API
#       belongs_to :blog
#    end
#
#    API::V1::Post.find(1).blog  #=>  #<API::V1::Blog:0x007ffa8a43f1e8 ...>
#
# The `:class_name` option still can be specified for alternate behavior
#
#    class API::V1::Post < Daylight::API
#       belongs_to :author, class_name: 'api/v1/user', foreign_key: 'created_by'
#    end

module Daylight::ReflectionExt
  extend ActiveSupport::Concern

  included do
    ##
    # Determines and tests for the name with namespace and version.
    #
    # Falls back to the name of the association which was the original behavior
    # of `AssociationReflection`.
    #
    # See
    # ActiveResource::Reflection::AssociationReflection

    def expanded_name
      @expanded_name = begin
        candidate_name = [Daylight::API.namespace, Daylight::API.version, name.to_s.classify].join("::")
        candidate_name.classify.constantize # test for the name, raise if non-existant
        candidate_name.underscore
      rescue
        name.to_s # fallback to using the original functionality
      end
    end

    private
      ##
      # Uses the expanded or default name to derive the class name.  Changes
      # original `AssociationReflection` functionality.
      #
      # See
      # ActiveResource::Reflection::AssociationReflection.derive_class_name

      def derive_class_name
        return (options[:class_name] ? options[:class_name].to_s : expanded_name).classify
      end
  end
end

ActiveResource::Reflection::AssociationReflection.class_eval do
  include Daylight::ReflectionExt
end
