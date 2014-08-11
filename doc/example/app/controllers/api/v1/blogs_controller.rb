class API::V1::BlogsController < APIController
  handles :all

  # private
    def blog_params
      params.fetch(:blog, {}).permit(:name)
    end
end
