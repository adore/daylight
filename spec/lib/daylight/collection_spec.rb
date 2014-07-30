require 'spec_helper'

describe Daylight::Collection do

  class CollectionTestClass < Daylight::API
    scopes :foo, :bar
  end

  before do
    stub_request(:get, %r{#{CollectionTestClass.site}}).to_return(body: [].to_json)
  end

  describe :metadata do
    before do
      data = { collection: [{name: 'one'}, {name: 'two'}], meta: {data: 'baz'} }
      stub_request(:get, %r{#{CollectionTestClass.site}}).to_return(body: data.to_json)
    end

    it 'is retrieved before parsing' do
      collection = CollectionTestClass.all

      collection.metadata.should == {'data' => 'baz'}
    end

    it 'is passed to child elements' do
      collection = CollectionTestClass.all
      collection.each do |child|
        child.metadata.should ==  {'data' => 'baz'}
      end
    end
  end

  describe :first_or_initialize do

    describe 'with results' do
      before do
        data = [{name: 'one'}, {name: 'two'}]
        stub_request(:get, %r{#{CollectionTestClass.site}}).to_return(body: data.to_json)
      end

      it 'returns the first result' do
        result = CollectionTestClass.where(name: 'one').first_or_initialize
        result.should be_kind_of(CollectionTestClass)
        result.name.should == 'one'
      end
    end

    it 'reraises NoMethodErrors on initialize' do
      CollectionTestClass.stub(:new).and_raise(NoMethodError)

      expect { CollectionTestClass.where(name: 'one').first_or_initialize }.to \
        raise_error(StandardError, 'Cannot create resource from resource type: CollectionTestClass')
    end

    it 'returns an unsaved instance' do
      result = CollectionTestClass.where(name: 'two').first_or_initialize

      result.should be_kind_of(CollectionTestClass)
      result.should_not be_persisted
    end

    it 'adds known parameter values to attributes' do
      result = CollectionTestClass.where(name: 'two').first_or_initialize

      result.should be_kind_of(CollectionTestClass)
      result.should_not be_persisted

      result.name.should == 'two'
    end

    it 'adds query parameter to prefix_options' do
      result = CollectionTestClass.foo.bar.where(name: 'two').first_or_initialize

      result.should be_kind_of(CollectionTestClass)
      result.should_not be_persisted

      result.prefix_options.should == {scopes: [:foo, :bar]}
    end

    it 'keeps collection parameters from being merged into attributes' do
      result = CollectionTestClass.where(name: 'two').limit(10).offset(100).order(name: 'asc').first_or_initialize

      result.should be_kind_of(CollectionTestClass)
      result.should_not be_persisted

      result.attributes[:limit].should be_nil
      result.attributes[:offset].should be_nil
      result.attributes[:order].should be_nil
    end

    it 'leaves unknown paramters so they are merged into attributes' do
      result = CollectionTestClass.find(:all, params: {a: 1, b: 2}).first_or_initialize

      result.should be_kind_of(CollectionTestClass)
      result.should_not be_persisted

      result.a.should == 1
      result.b.should == 2
    end
  end

  describe :first_or_create do

    describe 'with results' do
      before do
        data = [{name: 'one'}, {name: 'two'}]
        stub_request(:get, %r{#{CollectionTestClass.site}}).to_return(body: data.to_json)
      end

      it 'returns the first result' do
        result = CollectionTestClass.where(name: 'one').first_or_create
        result.should be_kind_of(CollectionTestClass)
        result.name.should == 'one'
      end
    end

    describe 'with errors' do
      before do
        errors = {errors: {status: ["can't be blank", "is not included in the list"]} }
        stub_request(:post, %r{#{CollectionTestClass.site}}).to_return(body: errors.to_json, status: 422)
      end

      it 'returns an unsaved instance with errors' do
        result = CollectionTestClass.where(name: 'one').first_or_create
        result.should be_kind_of(CollectionTestClass)
        result.should_not be_persisted

        result.name.should == 'one'
        result.errors.full_messages.should == ["Status can't be blank", "Status is not included in the list"]
      end

      it 'reraises NoMethodErrors on initialize' do
        CollectionTestClass.stub(:new).and_raise(NoMethodError)

        expect { CollectionTestClass.where(name: 'one').first_or_create }.to \
          raise_error(StandardError, 'Cannot build resource from resource type: CollectionTestClass')
      end
    end

    describe 'with create' do
      before do
        resource = {id: 1, name: 'one'}
        stub_request(:post, %r{#{CollectionTestClass.site}}).to_return(body: resource.to_json, status: 201)
      end

      it 'returns a saved instance' do
        result = CollectionTestClass.where(name: 'one').first_or_create

        result.should be_kind_of(CollectionTestClass)
        result.should be_persisted

        result.id.should == 1
      end

      it 'adds known parameter values to attributes' do
        result = CollectionTestClass.where(name: 'two').first_or_create

        result.should be_kind_of(CollectionTestClass)
        result.should be_persisted

        result.name.should == 'one'
      end

      describe 'before save' do
        before do
          CollectionTestClass.any_instance.stub(save: true)
        end

        it 'adds query parameter to prefix_options before save' do
          result = CollectionTestClass.foo.bar.where(name: 'two').first_or_initialize

          result.should be_kind_of(CollectionTestClass)
          result.should_not be_persisted

          result.prefix_options.should == {scopes: [:foo, :bar]}
        end

        it 'keeps collection parameters from being merged into attributes' do
          result = CollectionTestClass.where(name: 'two').limit(10).offset(100).order(name: 'asc').first_or_create

          result.should be_kind_of(CollectionTestClass)
          result.should_not be_persisted

          result.attributes[:limit].should be_nil
          result.attributes[:offset].should be_nil
          result.attributes[:order].should be_nil
        end

        it 'keeps unknown paramters so they are merged into attributes' do
          result = CollectionTestClass.find(:all, params: {a: 1, b: 2}).first_or_create

          result.should be_kind_of(CollectionTestClass)
          result.should_not be_persisted

          result.a.should == 1
          result.b.should == 2
        end
      end

      describe 'after save' do
        it 'has no prefix_options' do
          result = CollectionTestClass.foo.bar.where(name: 'two').first_or_create

          result.should be_kind_of(CollectionTestClass)
          result.should be_persisted

          result.prefix_options.should == {}
        end

        it 'has no collection parameters' do
          result = CollectionTestClass.where(name: 'two').limit(10).offset(100).order(name: 'asc').first_or_create

          result.should be_kind_of(CollectionTestClass)
          result.should be_persisted

          result.attributes[:limit].should be_nil
          result.attributes[:offset].should be_nil
          result.attributes[:order].should be_nil
        end

        it 'keeps unknown paramters' do
          result = CollectionTestClass.find(:all, params: {a: 1, b: 2}).first_or_create

          result.should be_kind_of(CollectionTestClass)
          result.should be_persisted

          result.a.should == 1
          result.b.should == 2
        end
      end
    end
  end
end
