require 'spec_helper'

describe 'remote methods' do

  let(:post) { API::Post.first }

  before do
    post = Post.new(title: 'First Post!')
    post.comments << Comment.create(content: 'First!',  like_count: 3)
    post.comments << Comment.create(content: 'Second!', like_count: 1)
    post.comments << Comment.create(content: 'Third!',  like_count: 2)
    post.save
  end

  it 'calls remote methods on the server and returns client objects' do
    comments = post.top_comments
    comments.map(&:content).should == %w[First! Third! Second!]
  end

end
