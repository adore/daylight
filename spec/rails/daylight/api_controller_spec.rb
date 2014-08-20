require 'spec_helper'

class Suite < ActiveRecord::Base
  has_many :cases

  def odd_cases
    # computational results used by `remoted`
    cases.select {|c| c.id.odd? }
  end
end

class SuitesController < Daylight::APIController
  handles :all

  private
    def suite_params
      params.fetch(:suite, {}).permit(:name, :switch)
    end
end

class Case < ActiveRecord::Base
  belongs_to :suite
end

# defined second to prove `handles :all` in SuitesController doesn't
# publicize every subclass.
class TestCasesController < Daylight::APIController
  handles :create, :update, :destroy

  set_model_name      :case
  set_record_name     :result
  set_collection_name :results
end

class TestAppRecord < ActiveResource::Base
end

class TestErrorsController < Daylight::APIController
  set_model_name :test_app_record

  def raise_argument_error
    raise ArgumentError.new('this is my message')
  end

  def raise_record_invalid_error
    record = TestAppRecord.new
    record.errors.add 'foo', 'error one'
    record.errors.add 'bar', 'error two'
    raise ActiveRecord::RecordInvalid.new(record)
  end
end

describe Daylight::APIController, type: :controller do
  migrate do
    create_table :suites do |t|
      t.boolean :switch
      t.string  :name
    end

    create_table :cases, id: false do |t|
      t.primary_key :test_id
      t.integer     :suite_id
      t.string      :name
    end
  end

  before :all do
    FactoryGirl.define do
      factory :suite do
        name   { Faker::Name.name }
        switch false

        after(:create) do |suite|
          create_list :case,  3, suite: suite
        end
      end

      factory :case do
        name { Faker::Name.name }
      end
    end
  end

  after :all do
    Rails.application.reload_routes!
  end

  describe "rescues errors" do
    # rspec-rails does not honor the tests(controller) function
    def self.controller_class
     TestErrorsController
    end

    before do
      @routes.draw do
        get '/test_errors/raise_argument_error'
        get '/test_errors/raise_record_invalid_error'
      end
    end

    describe "rescue from ArgumentError" do
      it "has status of bad_request" do
        get :raise_argument_error

        assert_response :bad_request
      end

      it "returns the error message as JSON" do
        get :raise_argument_error

        body = JSON.parse(response.body)
        body['errors'].should == 'this is my message'
      end
    end

    describe "rescue from RecordInvalid" do
      it "has status of unprocessable_entity" do
        get :raise_record_invalid_error

        assert_response :unprocessable_entity
      end

      it "returns the record's errors as JSON" do
        get :raise_record_invalid_error

        body = JSON.parse(response.body)
        body['errors'].count.should == 2
        body['errors']['foo'].should == ['error one']
        body['errors']['bar'].should == ['error two']
      end
    end

    describe "rescue from UnpermittedParameters error" do
      def self.controller_class
        SuitesController
      end

      before do
        @routes.draw do
          resources :suites
        end
      end

      it "has status of unprocessable_entity" do
        post :create, suite: {unpermitted: 'attr'}

        assert_response :unprocessable_entity
      end

      it "reports errors for unpermitted attributes" do
        post :create, suite: {unpermitted: 'attr'}

        body = JSON.parse(response.body)
        body['errors']['unpermitted'].should == ['unpermitted parameter']
      end
    end

    describe "rescue from ForbiddenAttributesError" do
      def self.controller_class
        TestCasesController
      end

      before do
        @routes.draw do
          resources :test_cases, only: [:create]
        end
      end

      it "has status of unprocessable_entity" do
        post :create, case: {suite_id: 0}

        assert_response :bad_request
      end

      it "returns the record's errors as JSON" do
        post :create, case: {name: 'unpermitted'}

        assert_response :bad_request

        body = JSON.parse(response.body)
        body['errors'].should == 'parameters have not been permitted on this action'
      end
    end
  end

  describe "default configuration" do
    let(:controller) { SuitesController }

    it "uses controller name for record name" do
      controller.record_name.should == 'suite'
    end

    it "uses controller name for model name" do
      controller.model_name.should == 'suite'
    end

    it "uses 'collection' for collection name" do
      controller.collection_name.should == 'collection'
    end

    it "uses controller name for model key" do
      controller.send(:model_key).should == :suite
    end

    it 'determines model class' do
      controller.send(:model).should == Suite
    end

    it 'delegates primary key to model class' do
      controller.send(:primary_key).should == 'id'
    end

    it 'access record ivar' do
      c = controller.new

      c.send(:record=, 'foo')
      c.send(:record).should == 'foo'
      c.instance_variable_get('@suite').should == c.send(:record)
    end

    it 'access collection ivar' do
      c = controller.new

      c.send(:collection=, %w[foo bar])
      c.send(:collection).should == %w[foo bar]
      c.instance_variable_get('@collection').should == c.send(:collection)
    end
  end

  describe "custom configuration" do
    let(:controller) { TestCasesController }

    it "overrides record name" do
      controller.record_name.should == :result
    end

    it "overrides collection name" do
      controller.collection_name.should == :results
    end

    it "overrides model name" do
      controller.model_name.should == :case
    end

    it 'determines model key' do
      controller.send(:model_key).should == :case
    end

    it 'determines model class' do
      controller.send(:model).should == Case
    end

    it 'delegates primary key to determined model class' do
      controller.send(:primary_key).should == 'test_id'
    end

    it 'access record ivar' do
      c = controller.new

      c.send(:record=, 'foo')
      c.send(:record).should == 'foo'
      c.instance_variable_get('@result').should == c.send(:record)
    end

    it 'access collection ivar' do
      c = controller.new

      c.send(:collection=, %w[foo bar])
      c.send(:collection).should == %w[foo bar]
      c.instance_variable_get('@results').should == c.send(:collection)
    end
  end

  describe "API handling" do
    let(:suites_controller) { SuitesController.new }     # handles :all
    let(:cases_controller)  { TestCasesController.new }  # handles some
    let(:errors_controller) { TestErrorsController.new } # handles none

    it 'handles no API actions by default' do
      Daylight::APIController::API_ACTIONS.each do |action|
        errors_controller.should_not respond_to(action)
      end
    end

    it 'handles some API actions but not others' do
      allowed = [:create, :update, :destroy]
      denied  = Daylight::APIController::API_ACTIONS.dup - allowed

      allowed.each do |action|
        cases_controller.should respond_to(action)
      end

      denied.each do |action|
        cases_controller.should_not respond_to(action)
      end
    end

    it 'handles all API actions' do
      Daylight::APIController::API_ACTIONS.each do |action|
        suites_controller.should respond_to(action)
      end
    end
  end

  describe "common actions" do
    # rspec-rails does not honor the tests(controller) function
    def self.controller_class
      SuitesController
    end

    before do
      @routes.draw do
        resources :suites, associated: [:cases], remoted: [:odd_cases], controller: :suites
      end
    end

    let!(:suite1) { create(:suite, switch: true)  }
    let!(:suite2) { create(:suite, switch: false) }
    let!(:suite3) { create(:suite, switch: true)  }

    def parse_collection body, root='anonymous'
      JSON.parse(body).values.first.
        map(&:values).
        map(&:first).
        map(&:with_indifferent_access)
    end

    def parse_record body
      JSON.parse(body).with_indifferent_access
    end

    it 'responds to index' do
      get :index

      results = parse_collection(response.body)
      results.size.should == 3

      names = results.map {|suite| suite["name"] }
      names.should be_include(suite1.name)
      names.should be_include(suite2.name)
      names.should be_include(suite3.name)
    end

    it 'responds to index with refine_by' do
      get :index, filters: {switch: true}

      results = parse_collection(response.body)

      results.size.should == 2
      names = results.map {|suite| suite[:name] }
      names.should be_include(suite1.name)
      names.should be_include(suite3.name)
    end

    it 'creates a record' do
      post :create, suite: suite = FactoryGirl.attributes_for(:suite)

      result = parse_record(response.body)
      result[:name].should   == suite[:name]
      result[:switch].should == suite[:switch]

      response.headers['Location'].should == "/suites/#{result['id']}"
    end

    it 'shows a record' do
      post :show, id: suite2.id

      result = parse_record(response.body)
      result[:id].should     == suite2[:id]
      result[:name].should   == suite2[:name]
      result[:switch].should == suite2[:switch]
    end

    it 'updates a record' do
      patch :update, id: suite3.id, suite: {name: 'Rik Mayall'}

      Suite.find(suite3.id).name.should == 'Rik Mayall'
    end

    it 'deletes a record' do
      delete :destroy, id: suite1.id

      expect { Suite.find(suite1.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'retrieves associated records' do
      get :associated, id: suite1.id, associated: 'cases'

      results = parse_collection(response.body)
      results.size.should == 3

      test_ids = results.map {|tc| tc['test_id'] }
      test_ids.should be_include(suite1.cases[0].id)
      test_ids.should be_include(suite1.cases[1].id)
      test_ids.should be_include(suite1.cases[2].id)
    end

    it 'retrieves associated records with refine_by' do
      get :associated, id: suite1.id, associated: 'cases', limit: 1

      results = parse_collection(response.body)
      results.size.should == 1

      results.first['test_id'].should == suite1.cases.first.id
    end

    it 'retrieves remoted records' do
      get :remoted, id: suite1.id, remoted: 'odd_cases'

      results = parse_collection(response.body)
      results.size.should == 2

      odd_case_ids = suite1.odd_cases.map(&:test_id)

      ids = results.map {|suite| suite["test_id"] }
      ids.should be_include(odd_case_ids.first)
      ids.should be_include(odd_case_ids.last)
    end
  end

end
