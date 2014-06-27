class Comment < ActiveRecord::Base
  scope :legit, -> { where(spam: false) }

  belongs_to :post
  belongs_to :commenter, class_name: 'User'
end
