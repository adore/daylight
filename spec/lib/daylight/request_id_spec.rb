require 'spec_helper'

describe Daylight::RequestId do
  UUID_REGEX_FORMAT      = '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'

  let(:request_id) { Daylight::RequestId.new }
  let(:client_id)  { Daylight::RequestId.new('daylight-test') }

  describe :request_id do
    it 'generates a uuid' do
      request_id.generate.should =~ /^#{UUID_REGEX_FORMAT}$/
      request_id.current.should  =~ /^#{UUID_REGEX_FORMAT}$/
      request_id.to_s.should     =~ /^#{UUID_REGEX_FORMAT}$/
      request_id.inspect.should  =~ /^"#{UUID_REGEX_FORMAT}"$/
    end

    it 'generates a uuid with client_id' do
      client_id.generate.should =~ /^#{UUID_REGEX_FORMAT}\/daylight-test$/
      client_id.current.should  =~ /^#{UUID_REGEX_FORMAT}\/daylight-test$/
      client_id.to_s.should     =~ /^#{UUID_REGEX_FORMAT}\/daylight-test$/
      client_id.inspect.should  =~ /^"#{UUID_REGEX_FORMAT}\/daylight-test"$/
    end

    it 'stores the previous uuid' do
      request_id.current.should == request_id.previous
    end

    it 'uses the same uuid' do
      request_id.use do |uuid|
        request_id.current.should  == uuid
        request_id.current.should  == uuid
        request_id.previous.should == uuid
      end
    end

    it 'uses the same uuid "manually"' do
      uuid = request_id.use

      request_id.current.should  == uuid
      request_id.current.should  == uuid
      request_id.previous.should == uuid

      request_id.clear!

      request_id.current.should_not  == uuid
      request_id.previous.should_not == uuid
    end

    it 'uses a custom uuid' do
      request_id.use('UUID') do
        request_id.current.should  == 'UUID'
        request_id.current.should  == 'UUID'
        request_id.previous.should == 'UUID'
      end
    end

    it 'uses a custom uuid "manually"' do
      request_id.use uuid='UUID'

      request_id.current.should  == uuid
      request_id.current.should  == uuid
      request_id.previous.should == uuid

      request_id.clear!

      request_id.current.should_not  == uuid
      request_id.previous.should_not == uuid
    end

  end
end