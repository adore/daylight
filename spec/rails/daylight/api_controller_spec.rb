require 'spec_helper'

describe Daylight::APIController, type: :controller do

  #
  # Test classes
  #

  class Anonymous; end

  class Suite < ActiveRecord::Base
    # TODO: remove when incorporated into ActiveRecord::Base
    include Daylight::Refiners

    # weirdness with route_options only adding to anonymous controller,
    # this wouldn't normally happen as anonymous controllers do not get used.
    add_remoted :odd_cases
    has_many    :cases

    def odd_cases
      # computational results
      cases.select {|c| c.id.odd? }
    end
  end

  class SuitesController < Daylight::APIController
  end

  class Case < ActiveRecord::Base
    # TODO: remove when incorporated into ActiveRecord::Base
    include Daylight::Refiners

    belongs_to :suite
  end

  # defined second to prove `handles :all` in SuitesController doesn't
  # publicize every subclass.
  class TestsController < Daylight::APIController
    handles :create, :update, :destroy

    self.model_name  = :case
    self.record_name = :results
  end

  TestAppRecord = Class.new(ActiveResource::Base)

  controller(Daylight::APIController) do
    inherited(self)

    # act like SuitesController should
    self.model_name  = :suite
    self.record_name = :suites
    handles :all

    def raise_argument_error
      raise ArgumentError.new('this is my message')
    end

    def raise_record_invalid_error
      record = TestAppRecord.new
      record.errors.add 'foo', 'error one'
      record.errors.add 'bar', 'error two'
      raise ActiveRecord::RecordInvalid.new(record)
    end

    # strong parameters to permit mass-assignment
    def suite_params
      params.require(:suite).permit(:name, :switch)
    end

    # url helper to generate location url
    def anonymous_path model
      "/anonymous/#{model.to_param}"
    end
  end

  #
  # Hooks
  #

  before do
    @routes.draw do
      get '/anonymous/raise_argument_error'
      get '/anonymous/raise_record_invalid_error'

      resources :anonymous, associated: [:cases], remoted: [:odd_cases]
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
      end
    end
  end

  migrate do
    create_table :suites do |t|
      t.boolean :switch
      t.string  :name
    end

    create_table :cases, id: false do |t|
      t.primary_key :test_id
      t.integer     :suite_id
    end
  end

  after :all do
    Rails.application.reload_routes!
  end

  #
  # Specs
  #

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

  describe "default configuration" do
    let(:controller) { SuitesController }

    it "uses controller name for record name" do
      controller.record_name.should == 'suites'
    end

    it "uses controller name for model name" do
      controller.model_name.should == 'suites'
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
  end

  describe "custom configuration" do
    let(:controller) { TestsController }

    it "overrides record name" do
      controller.record_name.should == :results
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
  end

  describe "API handling" do
    let(:tests_controller)  { TestsController.new }
    let(:suites_controller) { SuitesController.new }

    it 'handles no API actions by default' do
      Daylight::APIController::API_ACTIONS.each do |action|
        suites_controller.should_not respond_to(action)
      end
    end

    it 'handles some API actions but not others' do
      allowed = [:create, :update, :destroy]
      denied  = Daylight::APIController::API_ACTIONS.dup - allowed

      allowed.each do |action|
        tests_controller.should respond_to(action)
      end

      denied.each do |action|
        tests_controller.should_not respond_to(action)
      end
    end

    it 'handles all API actions' do
      Daylight::APIController::API_ACTIONS.each do |action|
        @controller.should respond_to(action)
      end
    end
  end

  describe "common actions" do
    let!(:suite1) { create(:suite, switch: true)  }
    let!(:suite2) { create(:suite, switch: false) }
    let!(:suite3) { create(:suite, switch: true)  }

    def parse_collection body, root='anonymous'
      JSON.parse(body)[root].
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

      response.headers['Location'].should == @controller.anonymous_path(Suite.new(result))
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

      results = parse_collection(response.body, 'cases')
      results.size.should == 3

      test_ids = results.map {|tc| tc['test_id'] }
      test_ids.should be_include(suite1.cases[0].id)
      test_ids.should be_include(suite1.cases[1].id)
      test_ids.should be_include(suite1.cases[2].id)
    end

    it 'retrieves associated records with refine_by' do
      get :associated, id: suite1.id, associated: 'cases', limit: 1

      results = parse_collection(response.body, 'cases')
      results.size.should == 1

      results.first['test_id'].should == suite1.cases.first.id
    end

    it 'retrieves remoted records' do
      get :remoted, id: suite1.id, remoted: 'odd_cases'

      results = parse_collection(response.body, 'odd_cases')
      results.size.should == 2

      odd_case_ids = suite1.odd_cases.map(&:test_id)

      ids = results.map {|suite| suite["test_id"] }
      ids.should be_include(odd_case_ids.first)
      ids.should be_include(odd_case_ids.last)
    end
  end

end
