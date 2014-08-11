class API::V1::CommentsController < APIController
  handles :all

  private
    def comment_params
      params.fetch(:comment, {}).permit!
    end
end
