class API::V1::PostsController < APIController
  handles :index, :create, :show, :associated, :update, :remoted
end
