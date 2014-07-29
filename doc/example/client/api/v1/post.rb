class API::V1::Post < Daylight::API
  scopes :published, :recent, :edited

  belongs_to :blog
  belongs_to :author, class_name: 'api/v1/user'

  has_many :comments
  has_many :commenters, class_name: 'api/v1/user'
  has_many :suppressed_comments, class_name: 'api/v1/comment'

  has_one :company, through: :blog

  remote :top_comments,  class_name: 'api/v1/comment'

  # these don't exist server-side, they are here for error_handling tests
  scopes :liked
  has_many :spammers, class_name: 'api/v1/user'
  remote :top_spammers, class_name: 'api/v1/user'
end
