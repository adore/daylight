class API::V1::Blog < Daylight::API
  belongs_to :company
  has_many :posts
end
