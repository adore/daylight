module ReadOnlyAttributes
  extend ActiveSupport::Concern

  included do
    # place the read_only attributes along side the other class_attributes for a Serializer
    class_attribute :_read_only
    self._read_only = []
  end

  module ClassMethods
    ##
    # Records the attribues as read only then stores them as attributes
    #
    # See
    # ActiveModel::Serializer.attributes
    def read_only(*attrs)
      # strip predicate '?' marks of and convert them to symbols
      normalized_attrs = attrs.map { |a| a.to_s.gsub(/\?$/,'').to_sym }

      # record which attributes will be read only
      self._read_only = _read_only.dup
      self._read_only.push(*normalized_attrs).uniq

      # pass them off to attributes to do all the work
      attributes(*attrs)
    end
  end
end

# Add the ReadOnlyAttributes to the Serializer
ActiveModel::Serializer.class_eval do
  include ReadOnlyAttributes
end
