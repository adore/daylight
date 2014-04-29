require 'spec_helper'

describe Daylight::Errors do

  class BaseErrorTest < StandardError
    def initialize resposne, message=nill
      @message = 'base'
    end

    def to_s
      @message.dup
    end
  end

  class ErrorTest < BaseErrorTest
    include Daylight::Errors
  end

  def mock_response headers, body
    double(header: headers, body: body)
  end

  it 'ignores parsing with no body and content-type' do
    error = ErrorTest.new(mock_response({}, nil))

    error.messages.should == []
    error.to_s.should == 'base'
  end

  it 'sets no message for unknown content-type' do
    error = ErrorTest.new(mock_response({'content-type' => 'application/foo'}, 'bar error, no drink'))

    error.messages.should == []
    error.to_s.should == 'base'
  end


  describe :xml do
    let(:xml_error)    { '<errors><error>message</error></errors>' }
    let(:xml_errors)   { '<errors><error>problem 1</error><error>problem 2</error></errors>' }

    def xml_response body=nil
      mock_response({'content-type' => 'application/xml; charset=utf-8'}, body)
    end

    it 'parses no error' do
      error = ErrorTest.new(xml_response)

      error.messages.should == []
      error.to_s.should == 'base'
    end

    it 'parses one error' do
      error = ErrorTest.new(xml_response(xml_error))

      error.messages.should == ['message']
      error.to_s.should == 'base  Root Cause = message'
    end

    it 'parses multiple errors' do
      error = ErrorTest.new(xml_response(xml_errors))

      error.messages.should == ['problem 1', 'problem 2']
      error.to_s.should == 'base  Root Cause = problem 1, problem 2'
    end

    it 'handles decode errors and sets no messages' do
      error = ErrorTest.new(xml_response('bad data'))

      error.messages.should == []
      error.to_s.should == 'base'
    end
  end

  describe :json do
    let(:json_error)    { { errors: 'message'}.to_json }
    let(:json_errors)   { { errors: ['problem 1', 'problem 2'] }.to_json }

    def json_response body=nil
      mock_response({'content-type' => 'application/json; charset=utf-8'}, body)
    end

    it 'parses no error' do
      error = ErrorTest.new(json_response)

      error.messages.should == []
      error.to_s.should == 'base'
    end

    it 'parses one error' do
      error = ErrorTest.new(json_response(json_error))

      error.messages.should == ['message']
      error.to_s.should == 'base  Root Cause = message'
    end

    it 'parses multiple errors' do
      error = ErrorTest.new(json_response(json_errors))

      error.messages.should == ['problem 1', 'problem 2']
      error.to_s.should == 'base  Root Cause = problem 1, problem 2'
    end

    it 'handles decode errors and sets no messages' do
      error = ErrorTest.new(json_response('<bad data>'))

      error.messages.should == []
      error.to_s.should == 'base'
    end
  end
end
