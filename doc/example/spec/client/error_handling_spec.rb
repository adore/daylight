require 'spec_helper'

describe 'error handling' do
  it 'exposes client errors' do
    post = API::Post.new(body: 'what? no title?')
    post.save.should be_false
    post.errors.messages[:base].should include("Title can't be blank")
  end

  it 'will report non-permitted strong parameter errors' do
    blog = API::Blog.new(description: 'is not allowed')
    blog.save.should be_false
    blog.errors.messages[:description].should include("unpermitted parameter")
  end
end
