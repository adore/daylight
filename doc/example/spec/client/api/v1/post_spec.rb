require 'spec_helper'

describe API::V1::Post do

  let!(:author) { User.create(name: 'I.P. Freely') }

  before do
    Post.create(title: 'Yellow River',           author: author, published: true,  published_at: 1.week.ago)
    Post.create(title: 'Joys of Drinking Water', author: author, published: true,  published_at: Time.now)
    Post.create(title: 'Porcelain Dreams',       author: author, published: false, published_at: 1.hour.ago)
  end

  it 'performs simple queries' do
    posts = API::V1::Post.where(author_id: author.id)
    posts.count.should == 3
  end

  it 'performs simple chained queries' do
    first = API::V1::Post.where(author_id: author.id).first
    first.title.should == 'Yellow River'
  end

  it 'performs chained queries with a scope' do
    published = API::V1::Post.where(author_id: author.id).published
    published.count.should == 2
    titles = published.map(&:title)
    titles.should include('Yellow River')
    titles.should include('Joys of Drinking Water')
  end

  it 'performs chained queries with multiple scopes' do
    recently_published = API::V1::Post.where(author_id: author.id).published.recent
    recently_published.count.should == 1
    recently_published.first.title.should == 'Joys of Drinking Water'
  end

  it 'performs chained queries with limit and offset' do
    limited = API::V1::Post.where(author_id: author.id).limit(10).offset(1)
    limited.count.should == 2
    limited.first.title.should include('Joys of Drinking Water')
    limited.last.title.should include('Porcelain Dreams')
  end

  it 'does a chained query with ordering' do
    results = API::V1::Post.where(author_id: author.id).order(:published_at)
    results.map(&:title).should ==
      ['Yellow River', 'Porcelain Dreams', 'Joys of Drinking Water']
  end

  it 'does a find_by lookup by first match' do
    API::V1::Post.find_by(slug: 'yellow-river').title.should == 'Yellow River'
  end

  describe 'associations' do
    let(:post) { Post.first }
    let(:commenter1) { User.new(name: 'Justin Tyme') }
    let(:commenter2) { User.new(name: 'Amanda Huggenkiss') }

    before do
      post.comments << Comment.new(content: 'first!',  commenter: commenter1, spam: false)
      post.comments << Comment.new(content: 'second!', commenter: commenter2, spam: true)
      post.comments << Comment.new(content: 'third!',  commenter: commenter2, spam: false)
      post.save
    end

    it 'performs lookup and association' do
      comments = API::V1::Post.first.comments
      comments.count.should == 3
    end

    it 'performs a query on the lookup\'s association' do
      comments = API::V1::Post.first.comments.where(commenter_id: commenter2.id)
      comments.count.should == 2
      comments.first.content.should == 'second!'
      comments.last.content.should  == 'third!'
    end

    it 'performs a chained query on the lookup\'s association' do
      comment = API::V1::Post.first.comments.where(commenter_id: commenter2.id).first
      comment.content.should == 'second!'
    end

    it 'performs a chained query on the lookup\'s association with scope' do
      comments = API::V1::Post.first.comments.where(commenter_id: commenter2.id).legit
      comments.count.should == 1
      comments.first.content.should == 'third!'
    end
  end
end
