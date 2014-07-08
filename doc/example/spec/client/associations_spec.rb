require 'spec_helper'

describe 'associations' do

  it 'saves nested resources' do
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

end
