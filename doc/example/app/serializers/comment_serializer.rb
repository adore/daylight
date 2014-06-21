class CommentSerializer < ActiveModel::Serializer
  embed :ids

  attributes :id, :name, :content

  has_one :post
end
