class API::V1::Post < Daylight::API
  scopes :published

  belongs_to :blog
  belongs_to :author, class_name: 'api/v1/user'

  has_many :comments, through: :associated
  has_many :commenters, through: :associated, class_name: 'api/v1/comment'
  has_many :suppressed_comments, through: :associated, class_name: 'api/v1/comment'

  has_one :company, through: :blog

  remote :top_comments, class_name: 'api/v1/comment'
end
