##
# Methods in which to refine a query by a model's scopes or attributes
module Daylight::Refiners
  extend ActiveSupport::Concern

  ##
  # Helper to determine whether a request to use an attribute is valid or invalid
  # Keeps track of which attributes are part of the request.
  class AttributeSeive
    attr_reader :valid_attribute_names, :attribute_names

    ##
    # Initializes with the valid attributes and requested attributes
    def initialize valid_attribute_names, attribute_names
      @valid_attribute_names, @attribute_names = valid_attribute_names, [attribute_names].flatten.compact.map(&:to_s)
    end

    ##
    # List of the invalid attributes
    def invalid_attributes
      @invalid_attributes ||= attribute_names - (attribute_names & valid_attribute_names)
    end

    ##
    # List of the valid attributes
    def valid_attributes
      @valid_attributes ||= attribute_names & valid_attribute_names
    end

    ##
    # Returns +true+ if there are any invalid attributes
    #
    # See:
    # #invalid_attributes
    def attributes_valid?
      invalid_attributes.empty?
    end
  end

  ##
  # Mixin refiners into an +ActiveRecord+ model
  module ClassMethods
    include Daylight::Params

    ##
    # Returns currently registered scopes or empty Array
    def registered_scopes
      @registered_scopes ||= []
    end

    ##
    # Remember the name of +scopes+ that are defined by the model
    # This is a method chain and will call ActiveRecord.scope
    def scope(name, body, &block)
      registered_scopes << name.to_s
      super
    end

    ##
    # Returns whether the +name+ matches a defined scope
    def scoped?(name)
      name.present? && registered_scopes.include?(name.to_s)
    end

    ##
    # Calls defined scopes on the model and returns the resulting +ActiveRecord::Relation+.
    # Raises +ArgumentError+ if the model scope is unknown.
    def scoped_by *scope_names
      seive = AttributeSeive.new(registered_scopes, scope_names)
      raise ArgumentError, "Unknown scope: #{seive.invalid_attributes.join(',')}" unless seive.attributes_valid?

      seive.valid_attributes.inject(all) do |scopes, scope_name|
        scopes.send(scope_name)
      end
    end

    ##
    # Helper to return the defined reflection names
    #
    # See:
    # filter_by
    def reflection_names
      reflections.keys.map(&:to_s)
    end

    ##
    # Supplies where conditions and returns the resulting +ActiveRecord::Relation+.
    # Raises +ArgumentError+ if the keys are not valid attributes on the model.
    def filter_by params
      where (params||{}).with_indifferent_access.assert_valid_keys(attribute_names + reflection_names)
    end

    ##
    # Wrapper around +order+ to perform key checking to +attribute_names+
    # Raises +ArgumentError+ if the attribute is unknown.
    def order_by value
      keys =
        case value
          when String; value.split(',').map {|column| column.strip.split(/\s+/).first }
          when Hash;   value.keys
          when Array;  value
        end

      seive = AttributeSeive.new(self.attribute_names, keys)
      raise ArgumentError, "Unknown attribute: #{seive.invalid_attributes.join(',')}" unless seive.attributes_valid?

      order(value)
    end

    def refine_by params
      with_helper(params) do |helper|
        self.
          scoped_by(helper.scoped_params).
          filter_by(helper.filter_params).
          order_by(helper.order_params).
          limit(helper.limit_params).
          offset(helper.offset_params)
      end
    end

    def associated params
      with_helper(params) do |helper|
        self.
          find(params[:id]).
          associated(helper.associated_params).
          filter_by(helper.filter_params).
          order_by(helper.order_params).
          limit(helper.limit_params).
          offset(helper.offset_params)
      end
    end

    def remoted params
      with_helper(params) do |helper|
        self.
          find(params[:id]).
          remoted(helper.remoted_params)
      end
    end

    def remoted_methods
      @remoted_methods ||= []
    end

    def add_remoted(method)
      remoted_methods.push(method.to_sym).uniq!
    end

    def remoted?(method)
      remoted_methods.include? method.to_sym
    end
  end

  included do
    ##
    # Helper to follow a named association if it exists
    def associated name
      raise ArgumentError, "Unknown association: #{name}" unless self.class.reflection_names.include? name.to_s
      send(name)
    end

    def remoted method
      raise ArgumentError, "Unknown remote: #{method}" unless self.class.remoted? method
      public_send(method)
    end
  end
end
