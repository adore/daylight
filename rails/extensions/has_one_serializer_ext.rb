require 'active_model_serializers'

##
# Allows `:through`	options	to be specified	on has_one associations
#
# A `has_one` associations may be specified so that:
# 1. `belongs_to` which has a foreign_key
# 2. through another association
#
# For example:
#
#   class Foo
#     belongs_to :bar
#     belongs_to :biz, through: :bar
#   end
#
#  When the serializer is specified:
#
#    class FooSerializer
#      embed :ids
#
#      has_one :bar
#      has_one :biz
#    end
#
# The serializer does not know it doesn't have a direct association to "biz"
#
# In this case, the serializer will attempt to put the foreign_key for "biz"
# in the rendered json.  If the original `Foo` object is saved it will fail
# because it does not know about this foreign_key.
#
# HasOneThrough adds functionality to the serializer to specify through
# relationships will put "biz" data in an nested attributes hash instead.
# When used in concert with `accepts_nested_attributes_for`, the data
# will be passed correctly back to the update methods on `Foo`:
#
#    class FooSerializer
#      embed :ids
#
#      has_one :bar
#      has_one :biz, through: :bar
#    end

module ActiveModel::Serializer::Associations

  class HasOneThrough < HasOne
    def embeddable?
      false
    end

    def key
      "#{through}_attributes"
    end

    def through
      option :through
    end

    def through_object
      @object ||= source_serializer.object.send(through)
    end

    def attributes
      source_serializer.node[key] || {}
    end

    def primary_key
      through_object.class.primary_key
    end

    def serialize
      return unless associated_object

      serialize_ids.merge({
        :"#{@name}_attributes" => find_serializable(associated_object).serializable_hash
      })
    end

    def serialize_ids
      return unless associated_object

      attributes.merge({
        :"#{primary_key}" => through_object.send(primary_key),
        :"#{@name}_id"    => associated_object.read_attribute_for_serialization(embed_key)
      })
    end
  end
end

module HasOneSerializerExt
  extend ActiveSupport::Concern

  included do
    attr_reader :node

    def self.has_one(*attrs)
      klass = if attrs.extract_options[:through]
          ActiveModel::Serializer::Associations::HasOneThrough
        else
          ActiveModel::Serializer::Associations::HasOne
        end

      associate(klass, attrs)
    end
  end
end

# Add the HasOneSerializerExt to the Serializer
ActiveModel::Serializer.class_eval do
  include HasOneSerializerExt
end
