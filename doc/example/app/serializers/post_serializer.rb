class PostSerializer < ActiveModel::Serializer
  embed :ids

  attributes :id, :title, :body

  has_one :blog
end
