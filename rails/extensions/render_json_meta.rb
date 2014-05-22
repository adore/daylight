module RenderJsonMeta
  extend ActiveSupport::Concern

  included do
    ##
    # Hooks into ActiveModelSerializer's ActionController::Serialization `_render_option_json` method
    def _render_option_json(resource, options)
      # All modules that are included will be able to add to the metadata hash
      metadata = (options[:meta] || {}).tap do |metadata|
        _add_meta_data(resource, metadata)
      end
      options[:meta] = metadata unless metadata.blank?

      super
    end
  end


  ##
  # Default metadata method (a no-op) that does not call `super`
  module MetadataDefault
    def _add_meta_data(resource, metadata); end
  end

  ##
  # For AssociationRelations, add known `where_values_hash` to the meta data
  module MetadataWhereValues
    def _add_meta_data(resource, metadata)
      if ActiveRecord::AssociationRelation === resource && resource.respond_to?(:where_values_hash)
        metadata[:where_values] = resource.where_values_hash
      end

      super
    end
  end

  ##
  # Adds `read_only` attributes from the serializer of the resource, or traverse
  # the AssociationRelation/Relation for each one of the collection's `read_only` attributes
  module MetadataReadOnly
    def _add_meta_data(resource, metadata)
      read_only_metadata = {}.tap do |attributes|
        if ActiveRecord::AssociationRelation === resource || ActiveRecord::Relation === resource
          resource.each { |model| read_only_attributes(model, attributes) }
        else
          read_only_attributes(resource, attributes)
        end
      end
      metadata[:read_only] = read_only_metadata unless read_only_metadata.blank?

      super
    end

    private
      def read_only_attributes(model, metadata)
        return if metadata[key = model.class.name.underscore]

        serializer = model.try(:active_model_serializer)
        if serializer.respond_to?(:read_only)
          metadata[key] = serializer._read_only if serializer.read_only
        end
      end
  end
end

# Hook all of the RenderJsonMeta modules into ActionController
# Each module will be chained together on the `_add_meta_data` method.
ActiveSupport.on_load(:action_controller) do
  include ::RenderJsonMeta

  # Modules could not be included within the concern, likely
  # because the context is lost from her in the on_load block
  include ::RenderJsonMeta::MetadataDefault
  include ::RenderJsonMeta::MetadataWhereValues
  include ::RenderJsonMeta::MetadataReadOnly
end
