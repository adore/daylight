require 'spec_helper'

class TestDescendant < Daylight::API
  self.password = nil

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
    @original_version   = Daylight::API.version.downcase
  end

  after do
    silence_warnings do
      Daylight::API.setup!({
        namespace: @original_namespace,
        endpoint: @original_endpoint,
        version: @original_version,
        password: @original_password
      })
    end
  end

  it 'raises an error if setup with bad version' do
    expect { Daylight::API.setup! version: 'v0' }.to raise_error(StandardError, /Unsupported version v0/)
  end

  it 'sets up site and prefix' do
    silence_warnings do
      Daylight::API.setup! endpoint: 'http://api.Daylight.test/', version: 'v1'
    end

    Daylight::API.site.to_s.should == 'http://api.Daylight.test/'
    Daylight::API.prefix.should == '/v1/'
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
      test.child_attributes['id'].should == 2
    end

    it "objectifies hashes within a known reflection's attributes" do
      test = TestDescendant.find(1)
      test.child_attributes['toy'].should be_kind_of(ActiveResource::Base)
      test.child_attributes['toy'].attributes.should == {'id' => 5, 'name' => 'slinky'}
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
end
