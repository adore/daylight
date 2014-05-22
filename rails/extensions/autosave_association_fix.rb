##
# The problem is that autosaving with models that have `inverse_of` and
# `accepts_nested_attributes_for` causes SystemStackError
#
# Solution is to keep track in an instance variable on each instance whether
# the object has been already autosaved.  On first pass it will determine if
# it needs saving (original behavior), later passes stop cyclic traversing by
# always return false.
#
# This should be removed when similar behavior is applied to ActiveRecord's
# `changed_for_autosave?`, likely candidate is 4.1.0 version of the gem.
#
# Original problem pulled together by:
# https://github.com/rails/rails/pull/8549
#
# Bug is is documented here:
# https://github.com/rails/rails/issues/7809
#
# Monkey patch supplied here:
# https://github.com/mtaylor/Rails-Inverse-Nested-Attr-Bug/blob/master/app/patches/rails/active_record/autosave_association.rb
#
# See
# ActiveRecord::Base#changed_for_autosave?

module AutosaveAssociationFix
  extend ActiveSupport::Concern

  # Returns whether or not this record has been changed in any way (including whether
  # any of its nested autosave associations are likewise changed)
  def changed_for_autosave?
    @_changed_for_autosave_called ||= false
    if @_changed_for_autosave_called
      # traversing a cyclic graph of objects; stop it
      result = false
    else
      begin
        @_changed_for_autosave_called = true
        result = super
      ensure
        @_changed_for_autosave_called = false
      end
    end
    result
  end
end

ActiveRecord::Base.class_eval do
  include AutosaveAssociationFix
end
