class API::V1::User < Daylight::API
  has_many :blogs
  has_many :posts
  has_many :comments
end
