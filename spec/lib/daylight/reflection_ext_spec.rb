require 'spec_helper'

describe Daylight::ReflectionExt do

  module TestAPI
    module V1; end
  end

  class TestFallback < Daylight::API; end

  class TestAPI::V1::Comment < Daylight::API; end

  class TestAPI::V1::Post < Daylight::API
    has_many :comments,     use: 'resource'
    has_many :top_comments, use: 'resource', class_name: 'test_api/v1/comment'

    belongs_to :test_fallback
  end

  before do
    post_data     = {id: 1, title: 'Test Post', test_fallback_id: 3}
    comments_data = [{body: 'comment 1'}, {body: 'comment 2'}]
    fallback_data = {id: 3, name: 'Fallback'}

    stub_request(:get, %r{#{TestAPI::V1::Post.element_path(1)}}).to_return(body:    post_data.to_json)
    stub_request(:get, %r{#{TestAPI::V1::Comment.collection_path}}).to_return(body: comments_data.to_json)
    stub_request(:get, %r{#{TestFallback.element_path(3)}}).to_return(body:         fallback_data.to_json)
  end

  it 'expands class name with namespace and version' do
    comments = TestAPI::V1::Post.find(1).comments

    comments.size.should == 2
    comments.first.should be_kind_of(TestAPI::V1::Comment)
  end


  it 'still overrides classname' do
    comments = TestAPI::V1::Post.find(1).top_comments

    comments.size.should == 2
    comments.first.should be_kind_of(TestAPI::V1::Comment)
  end

  it 'falls back to old behavior when class with expanded_name cannot be determined' do
    fallback = TestAPI::V1::Post.find(1).test_fallback

    fallback.should be_kind_of(TestFallback)
  end
end