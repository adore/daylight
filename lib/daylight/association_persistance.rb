module Daylight::AssociationPersistance

  # has our attributes changed since we were loaded?
  def changed?
    new? || hashcode != attributes.hash
  end

  def serializable_hash(options=nil)
    super((options || {}).reverse_merge(include: association_includes))
  end

  protected

    ##
    # returns nil if no changes (ourself or our children)
    # returns empty hash if we've changed, but our children haven't
    # returns include key if some of our children have changed
    #
    # { include: { post: { include: { comment: {} } } }

    def association_includes
      include_hash = {}

      self.class.reflection_names.each do |reflection_name|
        association = instance_variable_get("@#{reflection_name}")
        reflection_attribute_name = "#{reflection_name}_attributes"
        # ignore associations that have not been set
        next unless association

        # recurse into the child(ren)
        child_include_hash =
          if association.respond_to?(:to_ary)
            # merge all the includes from all the children
            children_includes = association.to_ary.map {|child| child.association_includes }.compact
            children_includes.reduce(:merge) if children_includes.present?
          else
            association.association_includes
          end

        if child_include_hash.present?
          include_hash[reflection_attribute_name] = {include: child_include_hash}
        elsif child_include_hash || changed_associations.include?(reflection_name)
          include_hash[reflection_attribute_name] = {}
        end
      end

      include_hash if changed? || include_hash.present?
    end

    ##
    # list of associations that have been modified
    #
    def changed_associations
      association_hashcodes.select {|association, code| send(association).hash != code }
    end

end
