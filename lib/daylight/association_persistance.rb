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
        attribute_name = "#{reflection_name}_attributes"
        # ignore associations that have not been set
        next unless association
        # don't overwrite associations that already exist in the attributes hash
        next unless attributes[attribute_name].nil?

        # recurse into the child(ren)
        attributes[attribute_name] =
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
