module Daylight::AssociationPersistance

  def self.prepended(base)
    base.before_save :include_child_updates
  end

  # has our attributes changed since we were loaded?
  def changed?
    new? || hashcode != attributes.hash
  end

  protected

    # update the attributes for associations if they have changed
    def include_child_updates
      self.class.reflection_names.each do |reflection_name|
        association = instance_variable_get("@#{reflection_name}")
        reflection_attribute_name = "#{reflection_name}_attributes"
        # ignore associations that have not been set
        next unless association

        # recurse into the child(ren)
        attributes[reflection_attribute_name] =
          if Enumerable === association
            # currently we need to send ALL the children if any of them
            # have changed
            association.each {|child| child.include_child_updates }
            association.map(&:serializable_hash) if changed_associations.include?(reflection_name) || association.any?(&:changed?)
          else
            association.include_child_updates
            association.serializable_hash if changed_associations.include?(reflection_name) || association.changed?
          end
      end
    end

    def changed_associations
      association_hashcodes.select {|association, code| send(association).hash != code }
    end

end
