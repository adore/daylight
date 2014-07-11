class Post < ActiveRecord::Base
  scope :published, -> { where.not(published_at: nil) }
  scope :edited,    -> { where.not(edited_at: nil) }
  scope :recent,    -> { where('published_at > ?', 1.day.ago) }

  belongs_to :blog
  belongs_to :author, class_name: 'User'

  has_many :comments
  has_many :commenters, -> { uniq }, through: :comments, class_name: 'User'
  has_many :suppressed_comments, -> { where(spam: true) }, class_name: 'Comment'

  has_one :company, through: :blog

  accepts_nested_attributes_for :comments, :author

  validates :title, presence: true

  before_create do
    self.slug = title.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
  end

  def published?
    published_at.present?
  end

  def edited?
    edited_at.present?
  end

  def top_comments
    comments.order_by('like_count DESC').limit(3)
  end
end
