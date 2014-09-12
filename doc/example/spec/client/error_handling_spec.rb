require 'spec_helper'

describe 'error handling' do
  it 'exposes client validation errors' do
    post = API::Post.new(body: 'what? no title?')
    post.save.should be_false
    post.errors.messages[:base].should include("Title can't be blank")
  end

  it 'reports non-permitted strong parameter errors' do
    blog = API::Blog.new(description: 'is not allowed')
    blog.save.should be_false
    blog.errors.messages[:description].should include("unpermitted parameter")
  end

  it 'reports on bad create attributes' do
    post = API::Post.new(foo: 'bar')
    expect{ post.save }.to raise_error(ActiveResource::BadRequest, /unknown attribute: foo/i)
  end

  it 'reports on bad query parameters' do
    expect{ API::Post.find_by(foo: 'bar') }.to raise_error(ActiveResource::BadRequest, /unknown key: "?foo"?/i)
  end

  it 'reports on invalid server-side statements' do
    # need to_a here so the ResourceProxy actually performs the request
    expect{ API::Post.published.limit(:foo).to_a }.to raise_error(ActiveResource::BadRequest, /invalid value for integer\(\): "foo"/i)
  end

  it 'raises an error on unknown scopes' do
    # need to_a here so the ResourceProxy actually performs the request
    expect{ API::Post.liked.to_a }.to raise_error(ActiveResource::BadRequest, /unknown scope: liked/i)
  end

  it 'raises an error on unknown remotes' do
    Post.create(title: 'unknown remote test')
    expect{ API::Post.first.top_spammers }.to raise_error(ActiveResource::BadRequest, /unknown remote: top_spammers/i)
  end

  it 'raises an error on unknown associations' do
    Post.create(title: 'unknown association test')
    expect{ API::Post.first.spammers.to_a }.to raise_error(ActiveResource::BadRequest, /unknown association: spammers/i)
  end
end
