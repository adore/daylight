class API::V1::Post < Daylight::API
  belongs_to :blog

  has_many :comments
end
