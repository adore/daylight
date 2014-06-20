class BlogSerializer < ActiveModel::Serializer
  embed :ids

  attributes :id
end
