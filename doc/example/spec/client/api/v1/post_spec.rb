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

  it 'chained query with ordering' do
    results = API::V1::Post.where(author_id: author.id).order(:published_at)
    results.map(&:title).should ==
      ['Yellow River', 'Porcelain Dreams', 'Joys of Drinking Water']
  end

  it 'does a find_by lookup by first match' do
    API::V1::Post.find_by(slug: 'yellow-river').title.should == 'Yellow River'
  end
end
