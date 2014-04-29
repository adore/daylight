require 'spec_helper'

describe Daylight do

  class RefinementTestClass < Daylight::API
    self.password = nil

    scopes :foo, :bar
  end

  before do
    data = [{name: 'one'}, {name: 'two'}]
    FakeWeb.register_uri(:get, %r{#{RefinementTestClass.site}}, :body => data.to_json)
  end

  describe Daylight::Refinements do

    it 'allows developers to define which scopes their models support' do
      RefinementTestClass.should respond_to(:foo)
      RefinementTestClass.should respond_to(:bar)

      RefinementTestClass.scopes :baz

      RefinementTestClass.should respond_to(:baz)
    end

    it 'resets the scopes between calls' do
      RefinementTestClass.foo.to_params[:scopes].should == [:foo]
      RefinementTestClass.bar.to_params[:scopes].should == [:bar]
    end

    it 'appends scopes' do
      RefinementTestClass.foo.bar.to_params[:scopes].should == [:foo, :bar]
    end

    it "supports where" do
      proxy = RefinementTestClass.where(baz: 'wibble')

      proxy.should be_kind_of(Daylight::ResourceProxy)
      proxy.to_params[:filters].should == {baz: 'wibble'}
    end

    it 'supports find_by' do
      # get a hook to the resource proxy
      proxy = RefinementTestClass.send(:resource_proxy)
      RefinementTestClass.stub(resource_proxy: proxy)

      result = RefinementTestClass.find_by(baz: 'wibble')
      result.should be_kind_of(RefinementTestClass)
      result.name.should == 'one'

      proxy.should be_kind_of(Daylight::ResourceProxy)
      proxy.to_params[:filters].should == {baz: 'wibble'}
      proxy.to_params[:limit].should == 1
    end

    it 'supports order' do
      proxy = RefinementTestClass.order(foo: 'asc')

      proxy.should be_kind_of(Daylight::ResourceProxy)
      proxy.to_params[:order].should == {foo: 'asc'}
    end

    it 'supports limit' do
      proxy = RefinementTestClass.limit(10)

      proxy.should be_kind_of(Daylight::ResourceProxy)
      proxy.to_params[:limit].should == 10
    end

    it 'supports offset' do
      proxy = RefinementTestClass.offset(100)

      proxy.should be_kind_of(Daylight::ResourceProxy)
      proxy.to_params[:offset].should == 100
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

    it 'creates a proxy object to support chaining' do
      proxy = RefinementTestClass.foo
      proxy.should be_kind_of(Daylight::ResourceProxy)

      proxy.should respond_to(:foo)
      proxy.should respond_to(:bar)

      # use everything!
      proxy = proxy.bar.where(baz: 'wibble').order(foo: 'asc').limit(10).offset(100)

      proxy.to_params[:scopes].should == [:foo, :bar]
      proxy.to_params[:filters].should == {baz: 'wibble'}
      proxy.to_params[:order].should == {foo: 'asc'}
      proxy.to_params[:limit].should == 10
      proxy.to_params[:offset].should == 100
    end


    it 'supports find_by with chaining' do
      proxy = RefinementTestClass.foo
      proxy.should be_kind_of(Daylight::ResourceProxy)

      result = proxy.find_by(baz: 'wibble')
      result.should be_kind_of(RefinementTestClass)
      result.name.should == 'one'

      proxy.to_params[:scopes].should == [:foo]
      proxy.to_params[:filters].should == {baz: 'wibble'}
      proxy.to_params[:limit].should == 1
    end
  end

end
