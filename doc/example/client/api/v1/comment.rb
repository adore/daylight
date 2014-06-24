class API::V1::Comment < Daylight::API
  belongs_to :post
  belongs_to :commenter, class_name: 'api/v1/comment'
end
