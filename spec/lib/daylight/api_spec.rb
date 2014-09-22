require 'spec_helper'

class TestDescendant < Daylight::API
  has_one :child, class_name: 'TestDescendant'
end

class TestAPIDescendantJSON < Daylight::API
  def self.format
    ActiveResource::Formats[:json]
  end
end

class TestAPIDescendantXML < Daylight::API
  def self.format
    ActiveResource::Formats[:xml]
  end
end

describe Daylight::API do
  def parse_xml(xml)
    data = Hash.from_xml(xml)

    if data.is_a?(Hash) && data.keys.size == 1
      data.values.first
    else
      data
    end
  end

  before do
    @original_namespace = Daylight::API.namespace
    @original_password  = Daylight::API.password
    @original_endpoint  = Daylight::API.endpoint
    @original_client_id = Daylight::API.request_id.client_id
    @original_version   = Daylight::API.version.downcase
  end

  after do
    silence_warnings do
      Daylight::API.setup!({
        namespace: @original_namespace,
        endpoint:  @original_endpoint,
        version:   @original_version,
        client_id: @original_client_id,
        password:  @original_password
      })
    end
  end

  it 'raises an error if setup with bad version' do
    expect { Daylight::API.setup! version: 'v0' }.to raise_error(StandardError, /Unsupported version v0/)
  end

  it 'sets up site and prefix' do
    silence_warnings do
      Daylight::API.setup! endpoint: 'http://api.daylight.test/', version: 'v1'
    end

    Daylight::API.site.to_s.should == 'http://api.daylight.test/'
    Daylight::API.prefix.should == '/v1/'
  end

  it 'handles sites with paths' do
    silence_warnings do
      Daylight::API.setup! endpoint: 'http://api.daylight.test/myapi', version: 'v1'
    end

    Daylight::API.site.to_s.should == 'http://api.daylight.test/myapi'
    Daylight::API.prefix.should == '/myapi/v1/'

    stub_request(:get, %r{#{TestDescendant.site}}).to_return(body: {}.to_json)

    TestDescendant.find(1)

    assert_requested :get, 'http://api.daylight.test/myapi/v1/test_descendants/1.json'
  end

  it 'sets request_root_in_json to true by default' do
    Daylight::API.request_root_in_json.should == true
    TestAPIDescendantJSON.request_root_in_json.should == true
    TestAPIDescendantXML.request_root_in_json.should == true
  end

  it 'returns request_root_in_json? based on format.extension' do
    TestAPIDescendantJSON.request_root_in_json?.should == true
    TestAPIDescendantXML.request_root_in_json?.should == false
  end

  it 'encodes setting only the root of the outer-most object' do
    inner = TestAPIDescendantJSON.new(name: 'inner')
    outer = TestAPIDescendantJSON.new(name: 'outer', tests: [inner])

    outer.encode.should == '{"test_api_descendant_json":{"name":"outer","tests":[{"name":"inner"}]}}'
  end

  it "doesn't set a client_id by default on the request_id" do
    Daylight::API.request_id.client_id.should be_nil
    TestAPIDescendantJSON.request_id.client_id.should be_nil
    TestAPIDescendantXML.request_id.client_id.should be_nil
  end

  it 'appends the client_id to the request_id' do
    silence_warnings do
      Daylight::API.setup! endpoint: 'http://api.daylight.test/', client_id: 'daylight-test'
    end

    Daylight::API.request_id.should be_a(Daylight::RequestId)
    Daylight::API.request_id.to_s.should =~ /\/daylight-test\z/
    TestAPIDescendantJSON.request_id.to_s.should =~  /\/daylight-test\z/
    TestAPIDescendantXML.request_id.to_s.should =~  /\/daylight-test\z/
  end

  describe :headers do
    it "adds X-Daylight-Framework header" do
      Daylight::API.headers['X-Daylight-Framework'].should_not be_nil
      Daylight::API.headers['X-Daylight-Framework'].should == Daylight::VERSION
      TestAPIDescendantJSON.headers['X-Daylight-Framework'].should == Daylight::VERSION
      TestAPIDescendantXML.headers['X-Daylight-Framework'].should == Daylight::VERSION
    end

    it "adds X-Request-Id header" do
      Daylight::API.headers['X-Request-Id'].should_not be_nil
      Daylight::API.headers['X-Request-Id'].should be_a(Daylight::RequestId)
      TestAPIDescendantJSON.headers['X-Request-Id'].should be_a(Daylight::RequestId)
      TestAPIDescendantXML.headers['X-Request-Id'].should be_a(Daylight::RequestId)
    end

    it "reuses the same Daylight::RequstId instance when headers are generated" do
      Daylight::API.headers['X-Request-Id'].should         == Daylight::API.headers['X-Request-Id']
      TestAPIDescendantJSON.headers['X-Request-Id'].should == Daylight::API.headers['X-Request-Id']
      TestAPIDescendantXML.headers['X-Request-Id'].should  == Daylight::API.headers['X-Request-Id']
    end
  end

  # works also when querying a belongs_to foreign key
  it 'returns nil when looking up a single record with a nil lookup' do
    TestDescendant.find(nil).should be_nil
  end

  describe "nested attributes" do
    before do
      data = {
        test_descendant: {
          id: 1,
          child_attributes: {
            id: 2,
            toy: {id: 5, name: 'slinky'}
          },
          other_attributes: {
            id: 4
          },
          other_hash: {
            id: 3
          }
        }
      }

      stub_request(:get, %r{#{TestDescendant.site}}).to_return(body: data.to_json)
    end

    it "does not objectify a known reflection's attributes" do
      test = TestDescendant.find(1)
      test.attributes['child_attributes']['id'].should == 2
    end

    it "objectifies hashes within a known reflection's attributes" do
      test = TestDescendant.find(1)
      toy = test.attributes['child_attributes']['toy']
      toy.should be_kind_of(ActiveResource::Base)
      toy.attributes.should == {'id' => 5, 'name' => 'slinky'}
    end

    it "still objectifies other attributes" do
      test = TestDescendant.find(1)
      test.other_attributes.should be_kind_of(ActiveResource::Base)
    end

    it "still objectifies other hashes" do
      test = TestDescendant.find(1)
      test.other_hash.should be_kind_of(ActiveResource::Base)
    end
  end

  describe "nested_resources" do
    before do
      data = {
        test_descendant: { name: "foo", immutable: "readme"},
        meta: { test_descendant: { read_only: ["immutable"], nested_resources: ["test_resource"] } }
      }

      stub_request(:get, %r{#{TestDescendant.site}}).to_return(body: data.to_json)
    end

    it "is defined" do
      test = TestDescendant.find(1)

      test.nested_resources.should == ["test_resource"]
    end
  end

  describe "natural_key" do
    before do
      data = {
        test_descendant: { id: 1, name: "foo" },
        meta: { test_descendant: { natural_key: "name" } }
      }

      stub_request(:get, %r{#{TestDescendant.site}}).to_return(body: data.to_json)
    end

    it "is defined" do
      test = TestDescendant.find(1)

      test.natural_key.should == "name"
    end
  end

  describe 'metadata' do
    before do
      data = {
        test_descendant: { id: 1, name: "foo", immutable: "readme"},
        meta: { test_descendant: { read_only: ["immutable"], nested_resources: ["test_resource"] } }
      }

      stub_request(:any, %r{#{TestDescendant.site}}).to_return(body: data.to_json)
    end

    it "is extracted from the response" do
      test = TestDescendant.find(1)

      test.metadata.should be_present
      test.metadata['read_only'].should == ['immutable']
    end

    it "is extracted from the response on an update" do
      test = TestDescendant.find(1)
      test.metadata.should be_present
      test.metadata.clear
      test.metadata.should_not be_present

      test.save
      test.metadata.should be_present
    end

    it "is extracted from the response on a create" do
      test = TestDescendant.create(name: 'foo')
      test.metadata.should be_present
    end
  end

  describe :load_attributes_for do
    let(:test) { TestDescendant.new }

    it 'creates a resource from a Hash based on the name' do
      obj = test.send(:load_attributes_for, :test_descendant, {name: 'foo'})
      obj.should be_instance_of(TestDescendant)
      obj.name.should == 'foo'
    end

    it 'creates a resource for each Hash in an array' do
      obj = test.send(:load_attributes_for, :test_descendants, [{name: 'foo'}, {name: 'bar'}])
      obj.size.should == 2
      obj.first.should be_instance_of(TestDescendant)
      obj.first.name.should == 'foo'
    end

    it 'dups each object in a given array if it is not a Hash' do
      data = %w[one two three]
      obj = test.send(:load_attributes_for, :test_descendants, data)
      obj.size.should == 3
      obj.first.should be_instance_of(String)
      obj.first.should == 'one'
      obj.object_id.should_not == data.first.object_id
    end

    it 'otherwise creates a dup of the given value' do
      my_string = 'my string'
      obj = test.send(:load_attributes_for, :test_descendant, my_string)
      obj.should be_instance_of(String)
      obj.should == 'my string'
      obj.object_id.should_not == my_string.object_id
    end
  end
end
