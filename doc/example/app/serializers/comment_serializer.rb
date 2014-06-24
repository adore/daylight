class CommentSerializer < ActiveModel::Serializer
  embed :ids

  attributes :id, :name, :content, :like_count
  read_only :spam, :published_at

  has_one :post
end
