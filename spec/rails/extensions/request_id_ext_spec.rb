require 'spec_helper'

describe Daylight::RequestIdExt, type: [:controller] do
  let(:uuid_regex) { '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' }
  let(:headers)    { {} }
  let(:app)        { double(:app, call: [nil,headers,nil]) }
  let(:middleware) { ActionDispatch::RequestId.new(app) }


  it 'continues to set the action_dispatch.request_id env var' do
    middleware.call(env={})

    env['action_dispatch.request_id'].should =~ /\A#{uuid_regex}\z/
  end

  it 'continues to set the X-Request-Id header' do
    middleware.call({})

    headers['X-Request-Id'].should =~ /\A#{uuid_regex}\z/
  end

  it 'continues to allow X-Request-Id header to be customized' do
    middleware.call({'HTTP_X_REQUEST_ID' => uuid=SecureRandom.uuid})

    headers['X-Request-Id'].should == uuid
  end

  it "allows special characters (/-+=) on external X-Request-Id" do
    middleware.call({'HTTP_X_REQUEST_ID' => uuid="#{SecureRandom.uuid}/test=another+value"})

    headers['X-Request-Id'].should == uuid
  end

  it "continues to strip non-special characters" do
    middleware.call({'HTTP_X_REQUEST_ID' => "This?Is!Another&Test"})

    headers['X-Request-Id'].should == "ThisIsAnotherTest"
  end
end
