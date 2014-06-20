class API::V1::CommentsController < APIController
  handles :index, :create, :show, :associated, :update, :remoted
end
