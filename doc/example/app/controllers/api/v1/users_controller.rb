class API::V1::UsersController < APIController
  handles :all

  private
    def user_params
      params.fetch(:user, {}).permit!
    end
end
