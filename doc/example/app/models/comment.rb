class Comment < ActiveRecord::Base
  scope :legit,  -> { where(spam: false) }
  scope :edited, -> { where.not(edited_at: nil) }

  belongs_to :post
  belongs_to :commenter, class_name: 'User'

  def edited?
    edited_at.present?
  end
end
