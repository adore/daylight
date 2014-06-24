class PostSerializer < ActiveModel::Serializer
  embed :ids

  attributes :id, :title, :body
  read_only :published_at, :slug, :published?

  has_one :author
  has_one :company, through: :blog
end
