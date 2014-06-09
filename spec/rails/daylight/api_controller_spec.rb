require 'spec_helper'

describe Daylight::APIController, type: :controller do

  class Anonymous
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
end