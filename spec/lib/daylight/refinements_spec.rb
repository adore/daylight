require 'spec_helper'

describe Daylight do

  class RefinementTestClass < Daylight::API
    self.password = nil

    scopes :foo, :bar
  end

  before do
    data = [{name: 'one'}, {name: 'two'}]
    stub_request(:get, %r{#{RefinementTestClass.site}}).to_return(body: data.to_json)
  end

  describe Daylight::Refinements do

    it 'allows developers to define which scopes their models support' do
      RefinementTestClass.should respond_to(:foo)
      RefinementTestClass.should respond_to(:bar)

      RefinementTestClass.scopes :baz

      RefinementTestClass.should respond_to(:baz)
    end

    it 'supports first' do
      resource = RefinementTestClass.first

      resource.should be_kind_of(ActiveResource::Base)
      resource.name.should == 'one'
    end

    it 'supports first with arguments' do
      resource = RefinementTestClass.first(params: {order: 'name'})

      resource.should be_kind_of(ActiveResource::Base)
      resource.name.should == 'one'
    end

    [:where, :find_by, :order, :limit, :offset].each do |method|
      it "delegates '#{method}' to ResourceProxy" do
        RefinementTestClass.should respond_to(method)
      end
    end

    describe "ResourceProxy class" do
      it "added to subclasses" do
        RefinementTestClass.should be_const_defined(:ResourceProxy)
      end

      it "accessible from subclass" do
        RefinementTestClass.send(:resource_proxy_class).should == RefinementTestClass::ResourceProxy
      end

      it "produce a new instance" do
        RefinementTestClass.send(:resource_proxy).class.should == RefinementTestClass::ResourceProxy
      end
    end

  end
end
