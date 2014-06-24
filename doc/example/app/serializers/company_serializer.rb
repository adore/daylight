class CompanySerializer < ActiveModel::Serializer
  embed :ids

  attributes :id, :name
end
