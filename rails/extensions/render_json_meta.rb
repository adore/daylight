module RenderJsonMeta
  extend ActiveSupport::Concern

  included do
    ##
    # Hooks into ActiveModelSerializer's ActionController::Serialization `_render_option_json` method
    def _render_option_json(resource, options)
      # All modules that are included will be able to add to the metadata hash
      metadata = (options[:meta] || {}).tap do |metadata|
        _add_metadata(resource, metadata)
      end
      options[:meta] = metadata unless metadata.blank?

      super
    end
  end


  ##
  # Default metadata method (a no-op) that does not call `super`
  module MetadataDefault
    def _add_metadata(resource, metadata); end
  end

  ##
  # For AssociationRelations, add known `where_values_hash` to the meta data
  module MetadataWhereValues
    def _add_metadata(resource, metadata)
      if ActiveRecord::AssociationRelation === resource && resource.respond_to?(:where_values_hash)
        metadata[:where_values] = resource.where_values_hash
      end

      super
    end
  end

  ##
  # Returns the `natural_key` for the resource
  module MetadataNaturalKey
    def _add_metadata(resource, metadata)
      _collect_metadata(:natural_key, resource, metadata) do |model|
        model.class.natural_key if model.class.natural_key
      end
    end
  end

  ##
  # For AssociationRelations, add known `nested_resource_names` to the meta data
  module MetadataNestedResources
    def _add_metadata(resource, metadata)
      _collect_metadata(:nested_resources, resource, metadata) do |model|
        model.class.nested_resource_names if model.class.respond_to?(:nested_resource_names)
      end

      super
    end
  end

  ##
  # Adds `read_only` attributes from the serializer of the resource, or traverse
  # the AssociationRelation/Relation for each one of the collection's `read_only` attributes
  module MetadataReadOnly
    def _add_metadata(resource, metadata)
      _collect_metadata(:read_only, resource, metadata) do |model|

        serializer = model.try(:active_model_serializer)
        if serializer.respond_to?(:read_only)
          serializer._read_only if serializer.read_only
        end
      end

      super
    end
  end

  private
    def _collect_metadata(key, resource, metadata, &block)
      if ActiveRecord::AssociationRelation === resource || ActiveRecord::Relation === resource
        resource.each { |model| _assign_metadata(key, model, metadata, &block) }
      else
        _assign_metadata(key, resource, metadata, &block)
      end
    end

    def _assign_metadata(attribute_key, resource, metadata)
      class_key = resource.class.name.underscore

      # quick return if attribute is already computed
      return if metadata[class_key] && metadata[class_key][attribute_key]

      if results = yield(resource)
        metadata[class_key] ||= {}
        metadata[class_key].merge!({ attribute_key => results })
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
  include ::RenderJsonMeta::MetadataNaturalKey
  include ::RenderJsonMeta::MetadataWhereValues
  include ::RenderJsonMeta::MetadataNestedResources
  include ::RenderJsonMeta::MetadataReadOnly
end
