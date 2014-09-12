class BlogSerializer < ActiveModel::Serializer
  embed :ids

  attributes :id, :name, :description

  has_one :company
end
