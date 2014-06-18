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
    @original_password = Daylight::API.password
    @original_endpoint = Daylight::API.endpoint
    @original_version  = Daylight::API.version.downcase
  end

  after do
    silence_warnings do
      Daylight::API.setup! endpoint: @original_endpoint, version: @original_version, password: @original_password
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

  describe "read only attriubtes" do
    before do
      data = {
        test_descendant: { name: "foo", immutable: "readme"},
        meta: { read_only: { test_descendant: ["immutable"] } }
      }

      stub_request(:get, %r{#{TestDescendant.site}}).to_return(body: data.to_json)
    end

    it "is accessible" do
      test = TestDescendant.find(1)

      test.immutable.should == 'readme'
    end

    it "cannot be set" do
      test = TestDescendant.find(1)

      lambda { test.immutable = 'foo' }.should raise_error(NoMethodError)
    end

    it "does not respond to setter" do
      test = TestDescendant.find(1)

      test.should_not respond_to(:immutable=)
    end

    it "is excluded when generating json" do
      json = TestDescendant.find(1).to_json

      JSON.parse(json).keys.should_not include('immutable')
    end

    it "is excluded when generating json with child resource" do
      test1 = TestDescendant.find(1)
      test2 = TestDescendant.find(1)
      test1.attributes['child'] = test2

      json = JSON.parse(test1.to_json)
      json.keys.should_not include('immutable')

      json['child'].keys.should_not include('immutable')
    end

    it "is excluded when generating json with children collection" do
      test1 = TestDescendant.find(1)
      test2 = TestDescendant.find(1)
      test1.attributes['children'] = [test2]

      json = JSON.parse(test1.to_json)
      json.keys.should_not include('immutable')

      json['children'].map(&:keys).flatten.should_not include('immutable')
    end

    it "is excluded xml" do
      xml = TestDescendant.find(1).to_xml

      parse_xml(xml).keys.should_not include('immutable')
    end

    it "is excluded when generating json with child resource" do
      test1 = TestDescendant.find(1)
      test2 = TestDescendant.find(1)
      test1.attributes['child'] = test2

      xml = parse_xml(test1.to_xml)
      xml.keys.should_not include('immutable')

      xml['child'].keys.should_not include('immutable')
    end

    it "is excluded when generating json with children collection" do
      test1 = TestDescendant.find(1)
      test2 = TestDescendant.find(1)
      test1.attributes['children'] = [test2]

      xml = parse_xml(test1.to_xml)
      xml.keys.should_not include('immutable')

      xml['children'].map(&:keys).flatten.should_not include('immutable')
    end
  end
end
