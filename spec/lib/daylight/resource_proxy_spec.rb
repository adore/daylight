require 'spec_helper'

describe Daylight::ResourceProxy do

  class ProxyTestClass < Daylight::API
    self.password = nil

    scopes :foo, :bar
    has_many :related_proxy_test_classes, through: :associated

    def self.wibble
      'wibble'
    end
  end

  class RelatedProxyTestClass < Daylight::API
    self.password = nil
  end

  class ProxyTestClass1 < Daylight::API
    self.password = nil
  end

  class ProxyTestClass2 < Daylight::API
    self.password = nil
  end

  before do
    data = [{name: 'one'}, {name: 'two'}]
    [RelatedProxyTestClass, ProxyTestClass].each do |clazz|
      FakeWeb.register_uri(:get, %r{#{clazz.site}}, body: data.to_json)
    end
  end

  it "supports 'first' as delegated method" do
    ProxyTestClass.foo.first.name.should == 'one'
  end

  it "supports 'push' as an Array method" do
    mock    = ProxyTestClass.new(name: 'three')
    results = ProxyTestClass.foo

    results.should_not respond_to(:push)
    results.push(mock).last.name.should == 'three'

    # now has the delegate
    results.should respond_to(:push)
  end

  it "supports Enumerable methods" do
    ProxyTestClass.foo.map {|f| f.name}.should == %w[one two]
  end

  it "supports a set of Array methods" do
    result = ProxyTestClass.foo
    result.size.should == 2
    result.length.should == 2
    result.to_ary.should be_instance_of Array
    result.last.name.should == 'two'
    result[0].name.should == 'one'
  end

  it "supports class methods as calls on resource" do
    results = ProxyTestClass.foo

    results.should_not respond_to(:wibble)
    results.wibble.should == 'wibble'

    # now delegating on the defined
    results.should respond_to(:wibble)
    results.wibble.should == 'wibble'
  end

  it "loads and caches the records" do
    results = ProxyTestClass.foo
    records = results.records
    records.should == results.records
  end

  it "can reload the records" do
    FakeWeb.clean_registry
    data = [{name: 'one'}, {name: 'two'}]
    FakeWeb.register_uri(:get, %r{#{ProxyTestClass.site}}, :body => data.to_json)

    proxy = ProxyTestClass.foo
    results = ProxyTestClass.foo.load

    FakeWeb.clean_registry
    data = [{name: 'one'}, {name: 'two'}, {name: 'three'}]
    FakeWeb.register_uri(:get, %r{#{ProxyTestClass.site}}, :body => data.to_json)

    results.should_not == proxy.reload
    results.count.should == 2
    proxy.records.count.should == 3
  end

  it "supports ==" do
    ProxyTestClass.foo.should == ProxyTestClass.foo
  end

  it "still throws NoMethodError" do
    expect { ProxyTestClass.foo.not_a_method }.to raise_error(NoMethodError)
  end

  it "still throws NoMethodError on << when not association" do
    ProxyTestClass.foo.association_resource.should be_nil

    expect { ProxyTestClass.foo << ['foo class'] }.to raise_error(NoMethodError)
  end

  it 'appends via << to the end of the current set' do
    resource = ProxyTestClass.foo.first
    related  = RelatedProxyTestClass.new(name: 'three')
    existing = resource.related_proxy_test_classes.to_a.dup

    resource.related_proxy_test_classes << related
    resource.related_proxy_test_classes.should == existing + [related]
  end

  it 'continues to appends via << to the end of the current set (in attributes)' do
    resource = ProxyTestClass.foo.first
    related1  = RelatedProxyTestClass.new(name: 'three')
    related2  = RelatedProxyTestClass.new(name: 'four')
    existing = resource.related_proxy_test_classes.to_a.dup

    resource.related_proxy_test_classes << related1
    resource.related_proxy_test_classes << related2
    resource.related_proxy_test_classes.should == existing + [related1, related2]
  end

  it "shows custom inspect method" do
    # resource proxy data
    ProxyTestClass.foo.inspect.should match(/#<ProxyTestClass::ResourceProxy \[.*\] @current_params={:scopes=>\[:foo\]}>/)

    # results returned by the proxy
    ProxyTestClass.foo.inspect.should match(/#<ProxyTestClass:0x.* @attributes={"name"=>"one"}[^>]*>/)
    ProxyTestClass.foo.inspect.should match(/#<ProxyTestClass:0x.* @attributes={"name"=>"two"}[^>]*>/)
  end

  it "applies filters from where" do
    proxy = ProxyTestClass.foo.where(bar: 'baz')

    proxy.to_params[:filters].should == {bar: 'baz'}
  end

  it 'cannot create a bare ResourceProxy' do
    expect { Daylight::ResourceProxy.new }.to raise_error(NoMethodError, /private method `new' called for/)
  end

  it "defines ResourceProxy that is a singleton" do
    Daylight::ResourceProxy[ProxyTestClass].object_id.should == Daylight::ResourceProxy[ProxyTestClass].object_id
  end

  it "defines the ResourceProxy constant for each class" do
    ProxyTestClass1.should be_const_defined(:ResourceProxy)
    ProxyTestClass2.should be_const_defined(:ResourceProxy)

    ProxyTestClass1::ResourceProxy.name.should == 'ProxyTestClass1::ResourceProxy'
    ProxyTestClass2::ResourceProxy.name.should == 'ProxyTestClass2::ResourceProxy'
  end
end
