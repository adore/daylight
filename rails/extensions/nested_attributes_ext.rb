##
# Problem:  Nested attributes will will fail to associate two records if they both already exist
# Solution: Associate the existing records defined by 'id' attributes before updating them
#
# Idea abstracted from implementation detailed by:
# https://stackoverflow.com/questions/6346134/use-rails-nested-model-to-create-outer-object-and-simultaneously-edit-existi/12064875#12064875
module NestedAttributesExt
  extend ActiveSupport::Concern

  included do
    class_attribute :nested_resource_names
    self.nested_resource_names = [].freeze

    ##
    # Associate any existing records that may be missing before running any updates on them.
    #
    # See:
    # ActiveRecord::NestedAttributes#assign_nested_attributes_for_collection_association
    def assign_nested_attributes_for_collection_association association_name, attributes_collection
      return if attributes_collection.nil?

      return if is_collection_multilevel?(association_name)

      associate_existing_records(association_name, attributes_collection)
      unassociate_missing_records(association_name, attributes_collection)

      super
    end

    ##
    # Ignore any association with nil attributes
    #
    # See:
    # ActiveRecord::NestedAttributes#assign_nested_attributes_for_one_to_one_association
    def assign_nested_attributes_for_one_to_one_association(association_name, attributes)
      return if attributes.nil?

      super
    end
  end

  module ClassMethods
    ##
    # Saves off the reflection names that the nested attributes are accepted for.
    # Does not alter original behavoir or arguments.
    #
    # See:
    # ActiveRecord::NestedAttributes#accepts_nested_attributes_for
    def accepts_nested_attributes_for *attr_names
      nested_resources = attr_names.dup
      nested_resources.extract_options!
      self.nested_resource_names = nested_resources.map(&:to_sym).freeze

      super
    end
  end


  private
    ##
    # Determines unassociated records from existing records on the association and adds them
    def associate_existing_records(association_name, attributes_collection)

      # determine existing records, bail if there are none specified by 'id'
      attribute_ids = attributes_collection.map {|a| (a['id'] || a[:id]) }.compact
      return if attribute_ids.empty?

      association = association(association_name)
      foreign_key = association.reflection.foreign_key

      # unassociated records ids are those not existing in the association ids
      unassociated_record_ids = attribute_ids.map(&:to_s) - association.ids_reader.map(&:to_s)

      # we are about to set all foreign_keys, remove any foreign_key references in
      # unassigned records attributes so they don't get clobbered
      attributes_collection.map do |a|
        if unassociated_record_ids.include?((a['id'] || a[:id]).to_s)
          a.delete(foreign_key) || a.delete(foreign_key.to_sym)
        end
      end

      # concat the unassociated records to the association
      association.concat(association.klass.find(unassociated_record_ids))
    end

    ##
    # Determines removed records from existing records on the association and sets their
    # foreign keys to NULL
    def unassociate_missing_records(association_name, attributes_collection)
      # determine existing records, bail if there are none specified by 'id'
      attribute_ids = attributes_collection.map {|a| (a['id'] || a[:id]) }.compact

      association = association(association_name)

      # removed records are those that are not part of existing in the association
      removed_record_ids = association.ids_reader.map(&:to_s) - attribute_ids.map(&:to_s)

      # remove the records from the association
      association.delete(*removed_record_ids) unless removed_record_ids.empty?
    end

    ##
    # returns true if the collection is a has_many :through or has_and_belongs_to_many
    # association.
    #

    def is_collection_multilevel?(association_name)
      association = association(association_name)

      type = has_many_type(association)
      return false unless type

      logger.error <<-ERROR
Attempt to modify "#{association_name}" collection on #{self.class.name}.
  Ignoring modification for #{type} used with
  accepts_nested_attributes_for because it causes unexpected results.
ERROR
    end

    ##
    # Return a description of the association if it is a has_and_belongs_to_many
    # or a has_many :through.
    #
    # Takes differences between Rails 4.0 and 4.1 into account.

    def has_many_type(association)
      reflection = association.reflection
      if reflection.try(:has_and_belongs_to_many?) ||
         (reflection.parent_reflection &&
          reflection.parent_reflection.last.try(:macro) == :has_and_belongs_to_many)
        'has_and_belongs_to_many'
      elsif reflection.options.has_key?(:through)
        'has_many :through'
      end
    end
end

ActiveRecord::Base.class_eval do
  include NestedAttributesExt
end
