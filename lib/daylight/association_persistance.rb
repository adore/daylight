module Daylight::AssociationPersistance

  # has our attributes changed since we were loaded?
  def changed?
    new? || hashcode != attributes.hash
  end

  def serializable_hash(options=nil)
    super((options || {}).merge(include: construct_include))
  end

  protected

    # { include: { post: { include: { comment: {} } } }
    def construct_include
      include_hash = {}

      self.class.reflection_names.each do |reflection_name|
        association = instance_variable_get("@#{reflection_name}")
        reflection_attribute_name = "#{reflection_name}_attributes"
        # ignore associations that have not been set
        next unless association

        # recurse into the child(ren)
        if Enumerable === association
          # currently we need to send ALL the children if any of them
          # have changed
          children_includes = association.map {|child| child.construct_include }.compact
          children_include_hash = children_includes.reduce(:merge) if children_includes.present?
          if children_include_hash.present?
            include_hash[reflection_attribute_name] = {include: children_include_hash}
          elsif children_include_hash || changed_associations.include?(reflection_name)
            include_hash[reflection_attribute_name] = {}
          end
        else
          child_include = association.construct_include
          if !child_include.nil?
            include_hash[reflection_attribute_name] = {include: child_include}
          elsif changed_associations.include?(reflection_name)
            include_hash[reflection_attribute_name] = {}
          end
        end
      end

      include_hash if changed? || include_hash.present?
    end

    def changed_associations
      association_hashcodes.select {|association, code| send(association).hash != code }
    end

end
