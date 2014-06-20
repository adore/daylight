class PostSerializer < ActiveModel::Serializer
  embed :ids

  attributes :id
end
