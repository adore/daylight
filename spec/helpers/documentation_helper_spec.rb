require 'spec_helper'

describe DaylightDocumentation::DocumentationHelper do

  class TestModel < ActiveRecord::Base
    include Daylight::Associations

    has_many :users

    # override attribute names so we don't have to mock
    # out the database table
    def self.attribute_names
      ['name']
    end
  end

  before do
    # create routes for our test model
    Daylight::Documentation.routes.draw do
      resources :test_models, associated: [:users]
    end
  end

  after do
    # make sure our existing routes are reloaded
    Rails.application.reload_routes!
  end

  describe :model_verbs_and_routes do
    it "yields the route verb, path, and defaults hash for the model" do
      yielded = false
      verbs = %w[GET POST PUT PATCH DELETE]
      helper.model_verbs_and_routes TestModel do |verb, path, defaults|
        verbs.should include(verb)
        path.to_s.should =~ %r{/test_model}
        defaults.should be_a(Hash)
        yielded = true
      end

      yielded.should be_true
    end
  end

  describe :model_filters do
    it "returns list of the model's filters including attributes" do
      helper.model_filters(TestModel).should include('name')
    end

    it "returns list of the model's filters including associations" do
      helper.model_filters(TestModel).should include('users')
    end
  end

  describe :action_definition do
    it "returns a definition for an action" do
      helper.action_definition({action:'index'}, TestModel).should ==
        "Retrieves a list of test models"
    end

    it "handles associated" do
      helper.action_definition({action:'associated', associated:'foo_bar'}, TestModel).should ==
        "Returns test model's foo bars"
    end

    it "handles remoted" do
      helper.action_definition({action:'remoted', remoted:'baz'}, TestModel).should ==
        "Calls test model's remote method baz"
    end
  end

  describe :client_namespace do
    it "returns the client namespace" do
      helper.client_namespace.should == 'test_api'
    end
  end

  describe :api_version do
    it "returns the api version" do
      helper.api_version.should == 'v1'
    end
  end
end
