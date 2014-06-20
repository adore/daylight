class API::V1::BlogsController < APIController
  handles :index, :create, :show, :associated, :update, :remoted
end
