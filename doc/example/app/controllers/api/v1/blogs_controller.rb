class API::V1::BlogsController < APIController
  handles :all

  # private
    def blog_params
      params.require(:blog).permit(:name, :description)
    end
end
