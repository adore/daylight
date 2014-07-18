require 'spec_helper'

describe 'building' do

  describe :first_or_create do
    it 'saves the object if it does not already exist' do
      post = API::Post.where(title: '100 Best Albums of 2014').first_or_create
      post.should_not be_new

      post.body = "Ranked list of the 100 best albums so far in 2014"
      post.save.should be_true
    end

    it 'will instantiate but not save objects with validation errors' do
      post = API::Post.where(body: 'Once upon a time...').first_or_create
      post.should be_new
      post.errors.should be_present
      post.errors.messages[:base].should include("Title can't be blank")
    end

    it 'handles chaining' do
      author = User.create(name: 'dmcinnes')
      Post.create(title: "You won't believe what happens next!", author: author, published_at: 1.day.ago)

      latest_post = API::Post.where(author_id: author.id).order(:published_at).first_or_create
      latest_post.should_not be_new
      latest_post.author.id.should == author.id
    end
  end

  describe :first_or_initialize do
    it 'instatiates the object but not save it automatically' do
      post = API::Post.where(slug: '100-best-albums-of-2014').first_or_initialize({
        title: "Ranked list of the 100 best albums so far in 2014"
      })
      post.should be_new
      post.save.should be_true
    end
  end

  describe 'through associations' do

    let(:post) { API::Post.first }

    before do
      Post.create(title: 'Advance Stirings in Relation to the Foraging Abilities of Avian Species')
    end

    it 'can create an object based on a collection for an association' do
      comment = post.comments.first_or_initialize(content: "Am I the first comment?")
      comment.should be_new
      comment.post_id.should == post.id
      comment.save.should be_true
    end

    it 'also works with refinements' do
      Comment.create(content: 'First!', post: Post.first, like_count: 1)

      comment = post.comments.where(like_count: 1).first_or_create
      comment.should_not be_new
      comment.post_id.should == post.id

      # Update the message
      comment.content = "You really like me when I said: '#{comment.content}'"
      comment.save.should be_true
    end
  end

end
