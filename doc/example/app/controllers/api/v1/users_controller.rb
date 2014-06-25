class API::V1::UsersController < APIController
  handles :all

  private
    def user_params
      params.require(:user).permit(:name)
    end
end
