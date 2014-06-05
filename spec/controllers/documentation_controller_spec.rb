require 'spec_helper'

describe Daylight::DocumentationController do

  class TestModel < ActiveRecord::Base
  end

  it "renders an index" do
    get :index, :use_route => :daylight

    assert_response :success
  end

  it "renders an index for models" do
    get :model_index, :use_route => :daylight

    assert_response :success

    assigns[:models].should include(TestModel)
  end

  it "renders a model view" do
    get :model, model: 'test_model', :use_route => :daylight

    assert_response :success

    assigns[:model].should == TestModel
  end

end
