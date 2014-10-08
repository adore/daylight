require 'spec_helper'

describe DaylightDocumentation::DocumentationController do

  class DocumentationTestModel < ActiveRecord::Base
  end

  migrate do
    create_table :documentation_test_models do |t|
      t.string  :name
      t.integer :number
    end
  end

  it "renders an index" do
    get :index, :use_route => :daylight

    assert_response :success

    assigns[:models].should include(DocumentationTestModel)
  end

  it "renders a model view" do
    get :model, model: 'documentation_test_model', :use_route => :daylight

    assert_response :success

    assigns[:model].should == DocumentationTestModel
  end

  it "renders json schema for the given model" do
    get :schema, model: 'documentation_test_model', :use_route => :daylight

    assert_response :success

    json = JSON.parse response.body
    json['attributes']['number'].should == 'integer'
  end

end
