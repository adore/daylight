require 'spec_helper'

describe 'refinements' do

  let(:server_blog)   { Blog.create(name: "Freely's Feels") }
  let(:server_author) { User.create(name: "I.P. Freely") }

  describe 'conditions additions' do
    let!(:server_post) do
      Post.create(
        title:        "5 amazing things you probably didn't know about APIs",
        author:       server_author,
        blog:         server_blog,
        published_at: 1.week.ago
      )
    end

    it 'has a list of attriubtes that can be refined' do
      post = API::Post.find(server_post.id)
      post.attributes.keys.should include('id', 'title', 'body', 'published_at', 'slug', 'published', 'author_id')
    end

    it 'can be queried using find_by' do
      post = API::Post.find_by(slug:"5-amazing-things-you-probably-didnt-know-about-apis")
      post.slug.should == "5-amazing-things-you-probably-didnt-know-about-apis"
    end

    # Not using the published: true clause here because of an active record bug with type casting boolean values for sqlite3
    # More details here: https://github.com/att-cloud/daylight/issues/16
    it 'can chain where clauses' do
      posts = API::Post.where(author_id: server_author.id).where(blog_id: server_blog.id)
      posts.size.should == 1
      posts.first.author_id.should == server_author.id
      posts.first.blog_id.should == server_blog.id
    end
  end

  describe 'order' do
    before do
      Post.create(title: "one",   published_at: 1.day.ago)
      Post.create(title: "two",   published_at: 2.days.ago)
      Post.create(title: "three", published_at: 3.days.ago)
    end

    it 'can refine by order' do
      posts = API::Post.order(:published_at)
      posts.map(&:title).should == %w[three two one]
    end

    it 'can reverse the order' do
      posts = API::Post.order('published_at DESC')
      posts.map(&:title).should == %w[one two three]
    end
  end

  describe 'limit and offset' do
    before do
      (1..10).each do |count|
        Post.create(title: count.to_s)
      end
    end

    it 'can limit the results' do
      posts = API::Post.limit(1)
      posts.size.should == 1

      posts = API::Post.limit(8)
      posts.size.should == 8
    end

    it 'can offset which resources are returned' do
      posts = API::Post.all
      posts.map(&:title).should == %w[1 2 3 4 5 6 7 8 9 10]

      posts = API::Post.offset(5)
      posts.map(&:title).should == %w[6 7 8 9 10]
    end
  end

  describe 'scopes' do
    before do
      Post.create(title: 'Yellow River',           published_at: 1.week.ago, edited_at: nil)
      Post.create(title: 'Joys of Drinking Water', published_at: Time.now,   edited_at: 1.week.ago)
      Post.create(title: 'Porcelain Dreams',       published_at: nil,        edited_at: 1.day.ago)
    end

    it 'reports which scopes are available' do
      API::Post.scope_names.should == [:published, :recent, :edited, :liked]
    end

    it 'can be called directly on the client model class' do
      posts = API::Post.published

      posts.count.should == 2
      posts.first.should be_published
      posts.all? {|p| p.published_at.present? }.should be_true
    end

    it 'can be called multiple times on a model' do
      posts = API::Post.published.edited

      posts.count.should == 1
      posts.first.published_at.should be_present
      posts.first.edited_at.should be_present
    end
  end

  describe 'chaining from resource classes' do

    let(:blog) { Blog.new(name: "Freely's Feels") }
    let(:author) { User.create(name: 'I.P. Freely') }

    before do
      Post.create(title: 'Yellow River',           author: author, blog: blog, published_at: 1.week.ago)
      Post.create(title: 'Joys of Drinking Water', author: author, blog: blog, published_at: Time.now)
      Post.create(title: 'Porcelain Dreams',       author: author, blog: blog, published_at: 1.hour.ago)
      Post.create(title: 'Something Else',         author: nil,    blog: blog, published_at: 1.hour.ago)
      Post.create(title: 'Some Other Thing',       author: author, blog: nil,  published_at: 1.hour.ago)
    end

    it 'works in the simple case' do
      posts = API::Post.where(blog_id: blog.id)
      titles = posts.map(&:title)
      titles.count.should == 4
      titles.should include('Yellow River')
      titles.should include('Joys of Drinking Water')
      titles.should include('Porcelain Dreams')
      titles.should include('Something Else')
    end

    it 'works with two conditions' do
      posts = API::Post.where(blog_id: blog.id).where(author_id: author.id)
      titles = posts.map(&:title)
      titles.count.should == 3
      titles.should include('Yellow River')
      titles.should include('Joys of Drinking Water')
      titles.should include('Porcelain Dreams')
    end

    it 'allows ordering' do
      posts = API::Post.where(blog_id: blog.id).where(author_id: author.id).order(:published_at)
      posts.map(&:title).should == ['Yellow River', 'Porcelain Dreams', 'Joys of Drinking Water']
    end

    it 'allows offset' do
      posts = API::Post.where(blog_id: blog.id).where(author_id: author.id).order(:published_at).offset(1)
      posts.map(&:title).should == ['Porcelain Dreams', 'Joys of Drinking Water']
    end

    it 'allows limit' do
      posts = API::Post.where(blog_id: blog.id).where(author_id: author.id).order(:published_at).offset(1).limit(1)
      posts.map(&:title).should == ['Porcelain Dreams']
    end

    it 'allows first' do
      post = API::Post.where(blog_id: blog.id).where(author_id: author.id).order(:published_at).offset(1).limit(1).first
      post.title.should == 'Porcelain Dreams'
    end

    it 'saves context for each part of the chain' do
      published_posts = API::Post.published
      first_published = published_posts.order(:published_at).first

      first_published.title.should == 'Yellow River'
      published_posts.count.should == 5
    end
  end

  describe 'chaining from resource instances' do

    let(:post)    { API::Post.first }
    let(:reidmix) { API::User.find_by(name: 'reidmix') }

    before do
      post = Post.create(title: 'Yellow River')

      dmcinnes = User.create(name: 'dmcinnes')
      reidmix  = User.create(name: 'reidmix')

      Comment.create(content: 'First!',  post: post, edited_at: 1.day.ago,  like_count: 1, commenter: dmcinnes)
      Comment.create(content: 'Second!', post: post, edited_at: 2.days.ago, like_count: 2, commenter: dmcinnes)
      Comment.create(content: 'Third!',  post: post, edited_at: 3.days.ago, like_count: 2, commenter: reidmix)
      Comment.create(content: 'Fourth!', post: post, edited_at: nil,        like_count: 0, commenter: reidmix)
      Comment.create(content: 'Fifth!',  post: post, edited_at: 5.days.ago, like_count: 2, commenter: reidmix)
      Comment.create(content: 'Sixth!',  post: post, edited_at: 6.days.ago, like_count: 2, commenter: reidmix)
    end

    it 'works in the simple case' do
      comments = post.comments
      comments.count.should == 6
    end

    it 'isolates with scope' do
      comments = post.comments.edited
      comments.map(&:content).should == %w[First! Second! Third! Fifth! Sixth!]
    end

    # TODO should be able to use the user client object as a filter value
    # instead of using the ids
    it 'isolates with scope and filter' do
      comments = post.comments.where(commenter_id: reidmix.id)
      comments.map(&:content).should == %w[Third! Fourth! Fifth! Sixth!]
    end

    it 'isolates with scope and multiple filters' do
      comments = post.comments.where(commenter_id: reidmix.id).where(like_count: 2)
      comments.map(&:content).should == %w[Third! Fifth! Sixth!]
    end

    it 'isolates and orders with scope and multiple filters' do
      comments = post.comments.where(commenter_id: reidmix.id).where(like_count: 2).order(:edited_at)
      comments.map(&:content).should == %w[Sixth! Fifth! Third!]
    end

    it 'isolates and orders with scope and multiple filters and an offset' do
      comments = post.comments.where(commenter_id: reidmix.id).where(like_count: 2).order(:edited_at).offset(1)
      comments.map(&:content).should == %w[Fifth! Third!]
    end

    it 'isolates and orders with scope and multiple filters and an offset and limit' do
      comments = post.comments.where(commenter_id: reidmix.id).where(like_count: 2).order(:edited_at).offset(1).limit(1)
      comments.map(&:content).should == %w[Fifth!]
    end

    it 'returns the first isolated, ordered, scoped, filtered, offsetted and limited result' do
      comment = post.comments.where(commenter_id: reidmix.id).where(like_count: 2).order(:edited_at).offset(1).limit(1).first
      comment.content.should == 'Fifth!'
    end
  end

end
