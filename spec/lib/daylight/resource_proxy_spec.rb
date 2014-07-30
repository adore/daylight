require 'spec_helper'

describe Daylight::ResourceProxy do

  class ProxyTestClass < Daylight::API
    scopes :foo, :bar
    has_many :related_proxy_test_classes

    def self.wibble
      'wibble'
    end
  end

  class RelatedProxyTestClass < Daylight::API
    scopes :baz
  end

  class ProxyTestClass1 < Daylight::API ; end

  class ProxyTestClass2 < Daylight::API ; end

  before do
    data = [{name: 'one'}, {name: 'two'}]
    [RelatedProxyTestClass, ProxyTestClass].each do |clazz|
      stub_request(:get, %r{#{clazz.site}}).to_return(body: data.to_json)
    end
  end

  it "supports (missing) class methods as calls on resource" do
    results = ProxyTestClass.foo

    results.should_not respond_to(:wibble)
    results.wibble.should == 'wibble'

    # now delegating on the defined
    results.should respond_to(:wibble)
    results.wibble.should == 'wibble'
  end

  it "shows custom inspect method" do
    # resource proxy data
    ProxyTestClass.foo.inspect.should match(/#<ProxyTestClass::ResourceProxy \[.*\] @current_params={:scopes=>\[:foo\]}>/)

    # results returned by the proxy
    ProxyTestClass.foo.inspect.should match(/#<ProxyTestClass:0x.* @attributes={"name"=>"one"}[^>]*>/)
    ProxyTestClass.foo.inspect.should match(/#<ProxyTestClass:0x.* @attributes={"name"=>"two"}[^>]*>/)
  end

  describe "NoMethodError" do
    it "still thrown when chaining" do
      expect { ProxyTestClass.foo.not_a_method }.to raise_error(NoMethodError)
    end

    it "still thrown when appending to scopes" do
      ProxyTestClass.foo.association_resource.should be_nil

      expect { ProxyTestClass.foo << ['foo class'] }.to raise_error(NoMethodError)
    end
  end

  describe "Array methods" do
    it "supported as a generated method" do
      mock    = ProxyTestClass.new(name: 'three')
      results = ProxyTestClass.foo

      results.should_not respond_to(:push)
      results.push(mock).last.name.should == 'three'

      # now has the delegate
      results.should respond_to(:push)
    end

    it "supported as delegates" do
      result = ProxyTestClass.foo
      result.should == ProxyTestClass.foo
      result.size.should == 2
      result.length.should == 2
      result.to_ary.should be_instance_of Array
      result.last.name.should == 'two'
      result[0].name.should == 'one'
    end

    it "supported through Enumerable methods" do
      ProxyTestClass.foo.map {|f| f.name}.should == %w[one two]
    end
  end

  describe "results fetch" do
    it "is loaded and cached" do
      results = ProxyTestClass.foo
      records = results.records
      records.should == results.records
    end

    it "is reloadable" do
      WebMock.reset!
      data = [{name: 'one'}, {name: 'two'}]
      stub_request(:get, %r{#{ProxyTestClass.site}}).to_return(body: data.to_json)

      proxy = ProxyTestClass.foo
      results = ProxyTestClass.foo.load

      WebMock.reset!
      data = [{name: 'one'}, {name: 'two'}, {name: 'three'}]
      stub_request(:get, %r{#{ProxyTestClass.site}}).to_return(body: data.to_json)

      results.should_not == proxy.reload
      results.count.should == 2
      proxy.records.count.should == 3
    end

    it "is resetable" do
      WebMock.reset!
      data = [{name: 'one'}, {name: 'two'}]
      stub_request(:get, %r{#{ProxyTestClass.site}}).to_return(body: data.to_json)

      proxy = ProxyTestClass.foo
      results = ProxyTestClass.foo.load

      WebMock.reset!
      data = [{name: 'one'}, {name: 'two'}, {name: 'three'}]
      stub_request(:get, %r{#{ProxyTestClass.site}}).to_return(body: data.to_json)

      results.should_not == proxy.send(:reset)
      results.count.should == 2

      proxy.to_params.should == {}
      proxy.records.count.should == 3
    end

    it "is resetable with new conditions" do
      WebMock.reset!
      data = [{name: 'one'}, {name: 'two'}]
      stub_request(:get, %r{#{ProxyTestClass.site}}).to_return(body: data.to_json)

      proxy = ProxyTestClass.foo
      results = ProxyTestClass.foo.load

      WebMock.reset!
      data = [{name: 'one'}, {name: 'two'}, {name: 'three'}]
      stub_request(:get, %r{#{ProxyTestClass.site}}).to_return(body: data.to_json)

      results.should_not == proxy.send(:reset, {limit: 2})
      results.count.should == 2

      proxy.to_params[:limit].should == 2
      proxy.records.count.should == 3
    end
  end

  describe "current parameters" do
    it 'resets the scopes between calls' do
      ProxyTestClass.foo.to_params[:scopes].should == [:foo]
      ProxyTestClass.bar.to_params[:scopes].should == [:bar]
    end

    it 'appends scopes' do
      ProxyTestClass.foo.bar.to_params[:scopes].should == [:foo, :bar]
    end

    it "supports 'where'" do
      proxy = ProxyTestClass.where(baz: 'wibble')

      proxy.should be_kind_of(Daylight::ResourceProxy)
      proxy.to_params[:filters].should == {baz: 'wibble'}
    end

    it "supports 'order'" do
      proxy = ProxyTestClass.order(foo: 'asc')

      proxy.should be_kind_of(Daylight::ResourceProxy)
      proxy.to_params[:order].should == {foo: 'asc'}
    end

    it "supports 'limit'" do
      proxy = ProxyTestClass.limit(10)

      proxy.should be_kind_of(Daylight::ResourceProxy)
      proxy.to_params[:limit].should == 10
    end

    it "supports 'offset'" do
      proxy = ProxyTestClass.offset(100)

      proxy.should be_kind_of(Daylight::ResourceProxy)
      proxy.to_params[:offset].should == 100
    end

    it 'creates a ResourceProxy to support chaining' do
      proxy = ProxyTestClass.foo
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

    it "supports 'first'" do
      ProxyTestClass.first.name.should == 'one'
    end

    it "supports 'first' with chaining" do
      ProxyTestClass.foo.first.name.should == 'one'
    end

    it "supports 'find_by'" do
      # get a hook to the resource proxy
      proxy = ProxyTestClass.send(:resource_proxy)
      ProxyTestClass.stub(resource_proxy: proxy)
      proxy.should be_kind_of(Daylight::ResourceProxy)

      result = ProxyTestClass.find_by(baz: 'wibble')
      result.should be_kind_of(ProxyTestClass)
      result.name.should == 'one'
    end

    it "supports 'find_by' with chaining" do
      proxy = ProxyTestClass.foo
      proxy.should be_kind_of(Daylight::ResourceProxy)

      result = proxy.find_by(baz: 'wibble')
      result.should be_kind_of(ProxyTestClass)
      result.name.should == 'one'

      proxy.to_params[:scopes].should == [:foo]
    end

    it "spawns new ResourceProxy for each part of the chain" do
      proxy = ProxyTestClass.foo

      limit = proxy.bar.limit(1)
      proxy.object_id.should_not == limit.object_id

      limit.to_params.should == {limit: 1, scopes: [:foo, :bar]}
      proxy.to_params.should == {scopes: [:foo]}
    end
  end

  describe "associations" do
    it "returns associated collection" do
      resource = ProxyTestClass.foo.first
      results  = resource.related_proxy_test_classes

      results.size.should == 2

      associated = results.first
      associated.should be_kind_of(RelatedProxyTestClass)
      associated.name.should == 'one'
    end

    it "creates a ResourceProxy to support chaining" do
      resource = ProxyTestClass.foo.first
      proxy  = resource.related_proxy_test_classes.baz.where(name: 'wibble')

      proxy.should be_kind_of(Daylight::ResourceProxy)
      proxy.to_params.should == {scopes: [:baz], filters: {name: 'wibble'}}
    end

    it "spawns new ResourceProxy for each part of the chain" do
      resource = ProxyTestClass.foo.first
      proxy    = resource.related_proxy_test_classes.baz

      limit = proxy.limit(1)
      proxy.object_id.should_not == limit.object_id

      limit.to_params.should == {limit: 1, scopes: [:baz]}
      proxy.to_params.should == {scopes: [:baz]}
    end

    it 'adds to end of collection' do
      resource = ProxyTestClass.foo.first
      related  = RelatedProxyTestClass.new(name: 'three')
      existing = resource.related_proxy_test_classes.to_a.dup

      resource.related_proxy_test_classes << related
      resource.related_proxy_test_classes.should == existing + [related]
    end

    it 'adds multiples to end of collection' do
      resource = ProxyTestClass.foo.first
      related1  = RelatedProxyTestClass.new(name: 'three')
      related2  = RelatedProxyTestClass.new(name: 'four')
      existing = resource.related_proxy_test_classes.to_a.dup

      resource.related_proxy_test_classes << related1
      resource.related_proxy_test_classes << related2
      resource.related_proxy_test_classes.should == existing + [related1, related2]
    end
  end

  describe "ResourceProxy class" do
    it 'cannot create without factory' do
      expect { Daylight::ResourceProxy.new }.to raise_error(NoMethodError, /private method `new' called for/)
    end

    it "is a singleton" do
      Daylight::ResourceProxy[ProxyTestClass].object_id.should == Daylight::ResourceProxy[ProxyTestClass].object_id
    end

    it "defined for each subclass" do
      ProxyTestClass1.should be_const_defined(:ResourceProxy)
      ProxyTestClass2.should be_const_defined(:ResourceProxy)

      ProxyTestClass1::ResourceProxy.name.should == 'ProxyTestClass1::ResourceProxy'
      ProxyTestClass2::ResourceProxy.name.should == 'ProxyTestClass2::ResourceProxy'
    end
  end

end
