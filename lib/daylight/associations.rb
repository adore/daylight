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

      def call_remote(remoted_method, model, verb, args)
        response = self.method(verb).call(remoted_method, args)
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
      through = options.delete(:use).to_s
      return super if through == 'resource'

      create_reflection(:has_many, name, options).tap do |reflection|
        nested_attribute_key = "#{reflection.name}_attributes"

        # setup the resource_proxy to fetch the results
        define_cached_method reflection.name, cache_key: nested_attribute_key do
          # return a empty collection if this is a new record
          return self.send("#{reflection.name}=", []) if new?

          resource_proxy = resource_proxy_for(reflection, self)
          resource_proxy.from(association_path(reflection))
        end

        # define setter that places the value directly in the attributes using
        # the nested_attributes functionality server-side
        define_method "#{reflection.name}=" do |value|
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
    # ActiveResource::Associations#belongs_to

    def belongs_to name, options={}
      create_reflection(:belongs_to, name, options).tap do |reflection|

        nested_attribute_key = "#{reflection.name}_attributes"

        # setup the resource_proxy to fetch the results
        define_cached_method reflection.name, cache_key: nested_attribute_key do
          if attributes.include? name
            attributes[name]
          else
            reflection.klass.find(send(reflection.foreign_key))
          end
        end

        # Defines a setter caching the value in an instance variable for later
        # retrieval.  Stash value directly in the attributes using the
        # nested_attributes functionality server-side.
        define_method "#{reflection.name}=" do |value|
          attributes[reflection.foreign_key] = value.id           # set the foreign key
          instance_variable_set(:"@#{reflection.name}", value)    # set the cached value
        end
      end
    end

    ##
    # Adds getter and setter methods for `has_one` associations that are
    # through a `belongs_to` association.  Assumes that the information about
    # the association is generated in the nested attributes by a HasOneThrough
    # serializer.
    #
    # In this example, if we did not go through the identity association the
    # primary keys would be generated, but upon save, an error would be thrown
    # because it is an unknown attribute.  This only happens with `belongs_to`
    # methods as they contain the primary_key.
    #
    # For example, consider `user_id` and `zone_id` primary keys:
    #
    #   class PostSerializer < ActiveModel::Serializer
    #     embed :ids
    #
    #     has_one :blog
    #     has_one :company, :zone through: :blog
    #    end
    #
    # It will generate the following json:
    #
    #    {
    #      "post": {
    #        "id": 1,
    #        "blog_id": 2,
    #        "blog_attributes": {
    #          "id": 2,
    #          "company_id": 3
    #        }
    #      }
    #    }
    #
    # An ActiveResource can define `belongs_to` with :through to read from
    # nested attributes for fetching by primary_key or setting to save.
    #
    #   class Post < Daylight::API
    #     belongs_to :blog
    #     has_one    :company, through: :blog
    #   end
    #
    #  So that:
    #
    #   p = Post.find(1)
    #   p.blog      # => #<Blog @attributes={"id"=>1}>
    #   p.company   # => #<Company @attributes={"id"=>3}>
    #
    #  And setting these associations will work with passing validations:
    #
    #   p.company = Company.find(1)
    #   p.save  # => true

    def has_one_through name, options
      through = options.delete(:through).to_s

      create_reflection(:has_one, name, options).tap do |reflection|
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
    #
    # Allows the has_one :through association.
    #
    # See:
    # has_one_through

    def has_one(name, options = {})
      return has_one_through(name, options) if options.has_key? :through

      create_reflection(:has_one, name, options).tap do |reflection|
        define_cached_method reflection.name do
          reflection.klass.where(:"#{self.class.element_name}_id" => self.id).first
        end

        define_method "#{reflection.name}=" do |value|
          value.attributes[:"#{self.class.element_name}_id"] = self.id
          instance_variable_set(:"@#{reflection.name}", value)    # set the cached value
        end
      end
    end

    ##
    # Adds a method to the model that calls the remote action that either
    # gets or mutates data
    #
    # Example:
    #
    #   remote :posts_by_popularity, class_name: 'post', verb: :get
    #
    #   or
    #
    #   remote :posts_by_popularity, class_name: 'post', verb: :patch
    #

    def remote name, options
      create_reflection(:remote, name, options).tap do |reflection|
        define_cached_method(reflection.name) do |args=nil|
          call_remote(reflection.name, reflection.klass, reflection.options[:verb], args)
        end
      end
    end

    private
      def define_cached_method method_name, options={}, &block
        # define an uncached method to call
        uncached_method_name = :"#{method_name}_without_cache"
        define_method(uncached_method_name, block)

        # define the cached wrapper around the uncached method
        define_method method_name do |args=nil|
          ivar_name  = :"@#{method_name}"
          cache_key  = options[:cache_key] || method_name
          attributes = options.has_key?(:index) ? @attributes[options[:index]] : @attributes

          return instance_variable_get(ivar_name) if instance_variable_defined?(ivar_name)

          value =
            if attributes.include?(cache_key)
              load_attributes_for(method_name, attributes[cache_key])
            else
              if args
                send(uncached_method_name, args)
              else
                send(uncached_method_name)
              end
            end

          # Track of the association hashcode for changes
          association_hashcodes[method_name] = value.hash

          instance_variable_set ivar_name, value
        end

        # alias our wrapper so calls to the attributes work
        alias_method "#{method_name}_attributes", method_name
      end

  end
end
