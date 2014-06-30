require 'spec_helper'

class TestReadOnly < Daylight::API
  self.password = nil

  has_one :child, class_name: 'TestReadOnly'
end

describe Daylight::ReadOnly do
  def parse_xml(xml)
    data = Hash.from_xml(xml)

    if data.is_a?(Hash) && data.keys.size == 1
      data.values.first
    else
      data
    end
  end

  describe "read only attributes" do
    before do
      data = {
        test_read_only: { name: "foo", immutable: "readme"},
        meta: { test_read_only: { read_only: ["immutable"], nested_resources: ["test_resource"] } }
      }

      stub_request(:get, %r{#{TestReadOnly.site}}).to_return(body: data.to_json)
    end

    it "is defined" do
      test = TestReadOnly.find(1)

      test.read_only.should == ["immutable"]
    end

    it "is accessible" do
      test = TestReadOnly.find(1)

      test.immutable.should == 'readme'
    end

    it "cannot be set" do
      test = TestReadOnly.find(1)

      lambda { test.immutable = 'foo' }.should raise_error(NoMethodError)
    end

    it "does not respond to setter" do
      test = TestReadOnly.find(1)

      test.should_not respond_to(:immutable=)
    end

    it "is excluded when generating json" do
      json = TestReadOnly.find(1).to_json

      JSON.parse(json).keys.should_not include('immutable')
    end

    it "is excluded when generating json with child resource" do
      test1 = TestReadOnly.find(1)
      test2 = TestReadOnly.find(1)
      test1.attributes['child'] = test2

      json = JSON.parse(test1.to_json)
      json.keys.should_not include('immutable')

      json['child'].keys.should_not include('immutable')
    end

    it "is excluded when generating json with children collection" do
      test1 = TestReadOnly.find(1)
      test2 = TestReadOnly.find(1)
      test1.attributes['children'] = [test2]

      json = JSON.parse(test1.to_json)
      json.keys.should_not include('immutable')

      json['children'].map(&:keys).flatten.should_not include('immutable')
    end

    it "is excluded xml" do
      xml = TestReadOnly.find(1).to_xml

      parse_xml(xml).keys.should_not include('immutable')
    end

    it "is excluded when generating json with child resource" do
      test1 = TestReadOnly.find(1)
      test2 = TestReadOnly.find(1)
      test1.attributes['child'] = test2

      xml = parse_xml(test1.to_xml)
      xml.keys.should_not include('immutable')

      xml['child'].keys.should_not include('immutable')
    end

    it "is excluded when generating json with children collection" do
      test1 = TestReadOnly.find(1)
      test2 = TestReadOnly.find(1)
      test1.attributes['children'] = [test2]

      xml = parse_xml(test1.to_xml)
      xml.keys.should_not include('immutable')

      xml['children'].map(&:keys).flatten.should_not include('immutable')
    end
  end
end
