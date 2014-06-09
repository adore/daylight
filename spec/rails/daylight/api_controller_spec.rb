require 'spec_helper'

describe Daylight::APIController, type: :controller do

  class Anonymous; end

  class Suite
    def self.primary_key
      'id'
    end
  end

  class SuitesController < Daylight::APIController
    handles :all
  end

  class Case
    def self.primary_key
      'test_id'
    end
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

  before do
    @routes.draw do
      get '/anonymous/raise_argument_error'
      get '/anonymous/raise_record_invalid_error'
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
        @controller.should_not respond_to(action)
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
        suites_controller.should respond_to(action)
      end
    end
  end

end
