class UserSerializer < ActiveModel::Serializer
  embed :ids

  attributes :id, :name
end
