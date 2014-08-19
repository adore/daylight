module Daylight::AssociationPersistance

  def self.prepended(base)
    base.before_save :include_child_updates
  end

  def load(attributes, remove_root = false, persisted = false)
    super(attributes, remove_root, persisted)

    @attribute_hash_on_load = self.attributes.hash

    self
  end

  # has our attributes changed since we were loaded?
  def changed?
    attributes.hash != @attribute_hash_on_load
  end

  protected

    # update the attributes for assocations if they have changed
    def include_child_updates
      self.class.reflection_names.each do |reflection_name|
        association = instance_variable_get("@#{reflection_name}")
        next unless association

        # recurse into the child(ren)
        attributes["#{reflection_name}_attributes"] =
          if Enumerable === association
            # currently we need to send ALL the children if any of them
            # have changed
            association.each {|child| child.include_child_updates }
            association.map(&:serializable_hash) if association.any?(&:changed?)
          else
            association.include_child_updates
            association.serializable_hash if association.changed?
          end
      end
    end

end
