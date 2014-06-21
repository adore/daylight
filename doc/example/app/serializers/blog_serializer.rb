class BlogSerializer < ActiveModel::Serializer
  embed :ids

  attributes :id, :name, :description
end
