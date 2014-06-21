class PostSerializer < ActiveModel::Serializer
  embed :ids

  attributes :id, :title, :content

  has_one :blog
end
