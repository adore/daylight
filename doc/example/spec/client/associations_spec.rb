require 'spec_helper'

describe 'associations' do

  describe 'creating nested resources' do
    it 'saves' do
      post = API::Post.new
      post.title  = '100 Best Albums of 2014'
      post.author = API::User.new(name: 'reidmix')
      post.save.should be_true

      # reload the original object to see the new user
      post = API::Post.find(post.id)
      post.author.name.should == 'reidmix'
      post.author_id.should_not be_nil

      # you can look up the new user directly
      user = API::User.find(post.author_id)
      user.name.should == 'reidmix'
    end

    it 'saves on preexisting resources' do
      API::Post.create(title: 'Woodchuck Chucking Capacity')

      post = API::Post.first
      post.author = API::User.new(name: 'dmcinnes')
      post.save.should be_true

      # reload the original object to see the new user
      post = API::Post.first
      post.author.name.should == 'dmcinnes'
      post.author_id.should_not be_nil

      # you can look up the new user directly
      user = API::User.find(post.author_id)
      user.name.should == 'dmcinnes'
    end
  end

  describe 'creating nested resources in a collection' do
    it 'saves' do
      post = API::Post.new(title: 'Relative Avian Costs Bettween Local and Remote (Shrubbery) Locations')
      post.comments.should be_empty
      post.comments << API::Comment.new(content: 'First!')
      post.save.should be_true

      # reload the original object to see the new comment
      post = API::Post.first
      post.comments.size.should == 1
      post.comments.first.content.should == 'First!'

      # you can look up the new comment
      comment = API::Comment.find(post.comments.first.id)
      comment.content.should == 'First!'
    end

    it 'saves on preexisting resources' do
      API::Post.create(title: 'Consequences of Legume Containment Failure')

      post = API::Post.first
      post.comments.should be_empty
      post.comments << API::Comment.new(content: 'Last!')
      post.save.should be_true

      # reload the original object to see the new comment
      post = API::Post.first
      post.comments.size.should == 1
      post.comments.first.content.should == 'Last!'

      # you can look up the new comment
      comment = API::Comment.find(post.comments.first.id)
      comment.content.should == 'Last!'
    end
  end

  describe 'updating nested resources' do
    let(:post) { API::Post.first }

    before do
      Post.create(
        title: 'The High Exchange Rate of Limb-based Currency',
        author: User.create(name: 'Doug McInnes'),
        comments: [Comment.create(content:'Sounds Painful')]
      )
    end

    it 'updates through the parent' do
      post.author.name = 'Reid MacDonald'
      post.author.save.should be_true

      post = API::Post.first
      post.author.name.should == 'Reid MacDonald'
    end

    it 'updates through the child' do
      author = post.author
      author.name = 'Reid MacDonald'
      author.save.should be_true

      post = API::Post.first
      post.author.name.should == 'Reid MacDonald'
    end

    it 'updates in collections' do
      first_comment = post.comments.first
      first_comment.content = 'First!'
      first_comment.save.should be_true

      post = API::Post.first
      post.comments.first.content.should == 'First!'
    end
  end

  describe 'assocating nested resources' do
    let(:post) { API::Post.first }

    before do
      doug = User.create(name: 'dmcinnes')
      reid = User.create(name: 'reidmix')

      Post.create(
        title: 'Canine and Feline Precipication',
        author: doug
      )
      Comment.create(content: 'First!', commenter: doug)
    end

    it 'associates existing child resources' do
      post.author = API::User.find_by(name: 'reidmix')
      post.save.should be_true

      post = API::Post.first
      post.author.name.should == 'reidmix'
    end

    it 'associates existing child resources into a collection' do
      comment = API::User.find_by(name: 'dmcinnes').comments.first
      comment.should_not be_nil
      post.comments << comment
      post.save.should be_true

      post = API::Post.first
      post.commenters.find {|c| c.name == 'dmcinnes'}.should be_present
    end
  end

end
