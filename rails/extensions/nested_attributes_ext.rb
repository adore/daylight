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
      primary_key = association.klass.primary_key.to_sym

      # get known existing ids on the association
      existing_record_ids = if association.loaded?
          association.target.map(&primary_key)
        else
          association.scope.where(primary_key => attribute_ids).pluck(primary_key)
        end

      # unassociated records are those that are not part of existing in the association
      unassociated_record_ids = attribute_ids.map(&:to_s) - existing_record_ids.map(&:to_s)

      # we are about to set all foreign_keys, remove any foreign_key references in
      # unassigned records attributes so they don't get clobbered
      attributes_collection.map do |a|
        if unassociated_record_ids.include?((a['id'] || a[:id]).to_s)
          key = association.reflection.foreign_key
          a.delete(key) || a.delete(key.to_sym)
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
      return if attribute_ids.empty?

      association = association(association_name)
      primary_key = association.klass.primary_key.to_sym

      existing_record_ids = association.scope.pluck(primary_key)

      # removed records are those that are not part of existing in the association
      removed_record_ids = existing_record_ids.map(&:to_s) - attribute_ids.map(&:to_s)

      # remove the records from the association
      association.scope.delete(removed_record_ids) if removed_record_ids.present?
    end
end

ActiveRecord::Base.class_eval do
  include NestedAttributesExt
end
