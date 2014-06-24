class API::V1::PostsController < APIController
  handles :all

  def show
    super

    @post.update_attributes(:view_count, @post.view_count+1)
  end
end
