class API::V1::User < Daylight::API
  has_many :blogs,    through: :associated
  has_many :posts,    through: :associated
  has_many :comments, through: :associated
end
