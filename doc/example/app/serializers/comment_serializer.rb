class CommentSerializer < ActiveModel::Serializer
  embed :ids

  attributes :id
end
