class Blog < ActiveRecord::Base
  belongs_to :company
  has_many   :posts

  accepts_nested_attributes_for :posts
end
