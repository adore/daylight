require 'spec_helper'

describe 'building' do

  describe :first_or_create do
    it 'saves the object if it does not already exist' do
      post = API::Post.where(title: '100 Best Albums of 2014').first_or_create
      post.should_not be_new

      post.content = "Ranked list of the 100 best albums so far in 2014"
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

end
