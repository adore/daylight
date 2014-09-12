# Controller Actions

When your `APIController` handles all requests, like so:

  ````ruby

    class PostController < APIController
      handles :all
    end

  ````

Essentially, these are the actions that are run on its behalf:

  ````ruby

    class PostController < APIController

      # GET /posts.json
      #
      def index
        render json: Post.refine_by(params)
      end


      # POST /posts.json
      #
      def create
        @post = Post.new(params[:post])
        @post.save!

        render json: @post, status: :created, location: @post
      end

      # GET /posts/1.json
      #
      def show
        render json: Post.find(params[:id])
      end

      # PATCH/PUT /posts/1.json
      #
      def update
        Post.find(params[:id]).update!(params[:post])

        head :no_content
      end

      # DELETE /posts/1.json
      #
      def destroy
        Post.find(params[:id]).destroy

        head :no_content
      end

      # GET /posts/1/comments.json
      #
      def associated
        render json: Post.associated(params), root: associated_params
      end

      # GET /posts/1/all_authorized_users.json
      #
      def remoted
        render json: Post.remoted(params), root: remoted_params
      end
    end

  ````