class API::V1::Comment < Daylight::API
  scopes :legit, :edited
  belongs_to :commenter, class_name: 'api/v1/user'
end
