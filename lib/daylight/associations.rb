##
# Support for quering associations between client objects
#
module Daylight::Associations
  extend ActiveSupport::Concern

  included do
    private
      # All chains create a new instance of the ResourceProxy for the supplied resource
      def resource_proxy_for reflection, resource
        Daylight::ResourceProxy[reflection.klass].new({reflection.name => resource})
      end

      # builds the path to the associated collection based on the has_many reflection
      def association_path(reflection)
        prefix          = self.class.prefix
        collection_name = self.class.collection_name
        member_id       = URI.parser.escape id.to_s
        extension       = reflection.klass.format.extension

        "#{prefix}#{collection_name}/#{member_id}/#{reflection.name}.#{extension}"
      end

      def call_remote(remoted_method, model)
        response = get(remoted_method)
        # strip the root, but take into consideration metadata
        if Hash === response && response.has_key?(remoted_method.to_s)
          response = response[remoted_method.to_s]
        end
        case response
          when Array
            model.send(:instantiate_collection, response)
          when Hash
            model.send(:instantiate_record, response)
        end
      end
  end

  module ClassMethods

    def reflection_names
      reflections.keys.map(&:to_s)
    end

    ##
    # Support for the :through option so that the server-side handles the association.
    #
    #   Post.first.comments #=> GET /posts/1/comments.json
    #
    # Also adds the setter for assocations:
    #
    #   Post.first.comments = [new_comment]
    #
    # See:
    # ActiveResource::Associations#has_many

    def has_many name, options={}
      through = options.delete(:through).to_s
      return super unless through == 'associated'

      create_reflection(:has_many, name, options).tap do |reflection|
        nested_attribute_key = "#{reflection.name}_attributes"

        # setup the resource_proxy to fetch the results
        define_cached_method reflection.name, cache_key: nested_attribute_key do
          resource_proxy = resource_proxy_for(reflection, self)
          resource_proxy.from(association_path(reflection))
        end

        # define setter that places the value directly in the attributes using
        # the nested_attributes functionality server-side
        define_method "#{reflection.name}=" do |value|
          self.attributes[nested_attribute_key] = value
          instance_variable_set(:"@#{reflection.name}", value)
        end

      end
    end

    ##
    # Adds a setter to the original `belongs_to` method that uses nested_attributes.
    # Also, hands off the :through option to `belongs_to_through`.
    #
    # Example:
    #
    #    comment = Comment.find(1)
    #    comment.creator = current_user
    #
    # See:
    # #belongs_to_through
    # ActiveResource::Associations#belongs_to

    def belongs_to name, options={}
      return belongs_to_through(name, options) if options.has_key? :through

      # continue to let the original do all the work.
      super.tap do |reflection|

        # Defines a setter caching the value in an instance variable for later
        # retrieval.  Stash value directly in the attributes using the
        # nested_attributes functionality server-side.
        define_method "#{reflection.name}=" do |value|
          attributes[reflection.foreign_key] = value.id           # set the foreign key
          attributes["#{reflection.name}_attributes"] = value     # set the nested_attributes
          instance_variable_set(:"@#{reflection.name}", value)    # set the cached value
        end
      end
    end

    ##
    # Adds getter and setter methods for `belongs_to` associations that are
    # through another `belongs_to` association.  Assumes that the information
    # about the association is generated in the nested attributes by a
    # HasOneThrough serializer.
    #
    # In this example, if we did not go through the identity association the
    # primary keys would be generated, but upon save, an error would be thrown
    # because it is an unknown attribute.  This only happens with `belongs_to`
    # methods as they contain the primary_key.
    #
    # For example, consider `user_id` and `zone_id` primary keys:
    #
    #   class KeyPairSerializer < ActiveModel::Serializer
    #     embed :ids
    #
    #     has_one :identity
    #     has_one :user, :zone through: :identity
    #    end
    #
    # It will generate the following json:
    #
    #    {
    #      "key_pair": {
    #        "id": 1,
    #        "identity_id": 2,
    #        "identity_attributes": {
    #          "id": 2,
    #          "user_id": 3,
    #          "zone_id": 2
    #        }
    #      }
    #    }
    #
    # An ActiveResource can define `belongs_to` with :through to read from
    # nested attributes for fetching by primary_key or setting to save.
    #
    #   class KeyPair < ActiveResource::Base
    #     belongs_to :identity
    #     belongs_to :user, through: :identity
    #     belongs_to :zone, through: :identity
    #   end
    #
    #  So that:
    #
    #   kp = KeyPair.find(1)
    #   kp.identity  # => #<Identity @attributes={"id"=>1}>
    #   kp.user      # => #<User @attributes={"id"=>3}>
    #   kp.zone      # => #<Zone @attributes={"id"=>2}>
    #
    #  And setting these associations will work with passing validations:
    #
    #   kp.user = User.find(1)
    #   kp.save                 # => true

    def belongs_to_through name, options
      through = options.delete(:through).to_s

      create_reflection(:belongs_to, name, options).tap do |reflection|
        nested_attributes_key  = "#{reflection.name}_attributes"
        through_attributes_key = "#{through}_attributes"

        define_cached_method reflection.name, index: through_attributes_key do
          reflection.klass.find(attributes[through_attributes_key][reflection.foreign_key])
        end

        define_method "#{reflection.name}=" do |value|
          through_attributes = attributes["#{through}_attributes"] ||= {}

          through_attributes[reflection.foreign_key] = value.id
          through_attributes[nested_attributes_key]  = value
          instance_variable_set(:"@#{reflection.name}", value)
        end
      end
    end

    ##
    # Fix bug in has_one that is not creating the request correctly.
    # Use `where` functionality as it peforms the function that is needed

    def has_one(name, options = {})
      create_reflection(:has_one, name, options).tap do |reflection|
        define_cached_method reflection.name do
          reflection.klass.where(:"#{self.class.element_name}_id" => self.id).first
        end

        define_method "#{reflection.name}=" do |value|
          attributes["#{reflection.name}_attributes"] = value     # set the nested_attributes
          value.attributes[:"#{self.class.element_name}_id"] = self.id
          instance_variable_set(:"@#{reflection.name}", value)    # set the cached value
        end
      end
    end

    ##
    # Adds a method to the model that calls the remote action for its data.
    #
    # Example:
    #
    #   remote :all_members, class_name: 'user'
    #

    def remote name, options
      create_reflection(:remote, name, options).tap do |reflection|
        define_cached_method reflection.name do
          call_remote(reflection.name, reflection.klass)
        end
      end
    end

    private
      def define_cached_method method_name, options={},  &block
        # define an uncached method to call
        uncached_method_name = :"#{method_name}_without_cache"
        define_method(uncached_method_name, block)

        # define the cached wrapper around the uncached method
        define_method method_name do
          ivar_name  = :"@#{method_name}"
          cache_key  = options[:cache_key] || method_name
          attributes = options.has_key?(:index) ? @attributes[options[:index]] : @attributes

          if instance_variable_defined?(ivar_name)
            instance_variable_get(ivar_name)
          elsif attributes.include?(cache_key)
            attributes[cache_key]
          else
            instance_variable_set ivar_name, send(uncached_method_name)
          end
        end
      end

  end
end
