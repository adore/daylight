require 'spec_helper'

describe Daylight::Associations do

  class RelatedTestClass < Daylight::API
    self.password = nil
    self.include_format_in_path = false
  end

  class AssociationsTestClass < Daylight::API
    self.password = nil
    self.include_format_in_path = false

    has_many   :related_test_classes, through: :associated
    has_many   :things,        class_name: 'RelatedTestClass', through: :associated
    belongs_to :parent,        class_name: 'RelatedTestClass'
    belongs_to :grandparent,   class_name: 'RelatedTestClass', through: :parent
    remote     :remote_stuff,  class_name: 'RelatedTestClass'

    def id;        123; end
    def parent_id; 456; end
  end

  describe :has_many do

    before do
      data = [{name: 'one'}, {name: 'two'}]
      [RelatedTestClass, AssociationsTestClass].each do |clazz|
        FakeWeb.register_uri(:get, %r{#{clazz.site}}, body: data.to_json)
      end
    end

    it "creates a method that construts an ResourceProxy for the association" do
      proxy = AssociationsTestClass.new.related_test_classes

      proxy.should be_is_a Daylight::ResourceProxy
      proxy.resource_class.should == RelatedTestClass
    end

    it "creates a method that construts an ResourceProxy with context about the association" do
      resource = AssociationsTestClass.new
      proxy    = resource.related_test_classes

      proxy.association_name.should == :related_test_classes
      proxy.association_resource.should == resource
    end

    it "hits the association api endpoint" do
      AssociationsTestClass.new.related_test_classes.load

      FakeWeb.last_request.path.should == "/v1/associations_test_classes/123/related_test_classes.json"
    end

    it "caches the results of the association" do
      instance = AssociationsTestClass.new
      proxy = instance.related_test_classes
      instance.related_test_classes.should == proxy
    end

    it "fetches the results out of the attributes if they exist" do
      object = AssociationsTestClass.new
      object.attributes['related_test_classes_attributes'] = ['yay']
      assocation = object.related_test_classes
      assocation.should be_instance_of(Array)
      assocation.first.should == 'yay'
    end

    it "supports the :class_name option" do
      proxy = AssociationsTestClass.new.things
      proxy.resource_class.should == RelatedTestClass
    end

    it "chains using the proxy class for the associated model" do
      proxy = AssociationsTestClass.new.related_test_classes.where(wibble: 'wobble')

      proxy.resource_class.should == RelatedTestClass
      proxy.to_params[:filters].should == {wibble: 'wobble'}
    end

    it "sets the associations directly the attributes hash" do
      resource = AssociationsTestClass.new
      resource.related_test_classes = ["associated instances"]

      resource.attributes['related_test_classes_attributes'].should == ["associated instances"]
    end

    it "fetches the stored associations out of the attributes when they exist" do
      resource = AssociationsTestClass.new
      resource.related_test_classes = ["associated instances"]

      resource.related_test_classes.should == ["associated instances"]
    end
  end

  describe :belongs_to do

    before do
      data = { parent: {name: 'three'}}
      [RelatedTestClass, AssociationsTestClass].each do |clazz|
        FakeWeb.register_uri(:get, %r{#{clazz.site}}, body: data.to_json)
      end
    end

    it 'still fetches the parent object' do
      resource = AssociationsTestClass.find(1)

      resource.parent.should_not be_nil
      resource.parent.name.should == 'three'
    end

    it 'sets the parent to a new object' do
      resource = AssociationsTestClass.find(1)
      resource.parent = RelatedTestClass.new(name: 'new parent')

      resource.parent.name.should == 'new parent'
    end

    it 'sets the parent foreign key' do
      resource = AssociationsTestClass.find(1)
      resource.parent = RelatedTestClass.new(id: 789, name: 'new parent')

      resource.attributes['parent_id'].should == 789
    end

    it 'sets the parent directly in the nested attributes hash' do
      resource = AssociationsTestClass.find(1)
      resource.parent = RelatedTestClass.new(id: 789, name: 'new parent')

      resource.attributes['parent_attributes'].should == resource.parent
    end
  end

  describe :belongs_to_through do

    before do
      association_data = { through: {
          id: 1,
          parent_id: 456, # ignored because of parent_id method
          parent_attributes: {
            id: 456,
            grandparent_id: 3
          }
        }
      }

      embedded_data = { through: {
          id: 2,
          parent_id: 456, # ignored because of parent_id method
          parent_attributes: {
            id: 456,
            grandparent: { id: 4, name: 'embed' }
          }
        }
      }

      related_data = {id: nil, name: 'related'}

      FakeWeb.register_uri(:get, %r{#{AssociationsTestClass.element_path(1)}}, body: association_data.to_json)
      FakeWeb.register_uri(:get, %r{#{AssociationsTestClass.element_path(2)}}, body: embedded_data.to_json)
      FakeWeb.register_uri(:get, %r{#{RelatedTestClass.element_path(456)}},    body: related_data.merge(id: 456).to_json)
      FakeWeb.register_uri(:get, %r{#{RelatedTestClass.element_path(3)}},      body: related_data.merge(id: 3).to_json)
    end

    it 'still fetches the parent object' do
      resource = AssociationsTestClass.find(1)

      resource.parent.should_not be_nil
      resource.parent.id.should   == 456
      resource.parent.name.should == 'related'
    end

    it 'fetches the "through" object' do
      resource = AssociationsTestClass.find(1)

      resource.grandparent.should_not be_nil
      resource.grandparent.id.should   == 3
      resource.grandparent.name.should == 'related'
    end

    it 'fetches embedded "through" object' do
      resource = AssociationsTestClass.find(2)

      resource.grandparent.should_not be_kind_of(ActiveRecord::Base)
      resource.grandparent.id.should   == 4
      resource.grandparent.name.should == 'embed'
    end

    it 'sets the "through" object foreign key' do
      resource = AssociationsTestClass.find(1)
      resource.grandparent = RelatedTestClass.new(id: 789, name: 'new grandparent')

      resource.attributes['parent_attributes']['grandparent_id'].should == 789
    end

    it 'sets the through object directly in the nested attributes hash' do
      resource = AssociationsTestClass.find(1)
      resource.grandparent = RelatedTestClass.new(id: 789, name: 'new grandparent')

      resource.attributes['parent_attributes']['grandparent_attributes'].should == resource.grandparent
    end
  end

  describe :remote do

    def respond_with(data)
      FakeWeb.register_uri(:get, %r{#{AssociationsTestClass.site}}, body: data.to_json)
    end

    let(:subject) { AssociationsTestClass.new }

    it "loads data from the remote" do
      respond_with({remote_stuff: {id: 2, foo: 'bar'}})

      subject.remote_stuff.foo.should == 'bar'
    end

    it "handles collections" do
      respond_with({remote_stuff: [{id: 2, foo: 'first'}, {id: 3, foo: 'second'}]})

      subject.remote_stuff.first.foo.should == 'first'
      subject.remote_stuff.last.foo.should == 'second'
    end

    it "caches the data" do
      respond_with({remote_stuff: {cache: 'cachey cache'}})

      subject.should_receive(:get).once.and_call_original

      subject.remote_stuff.cache.should == 'cachey cache'
      subject.remote_stuff.cache.should == 'cachey cache'
    end

    it "handles metadata with an object" do
      respond_with({remote_stuff: {id: 2, foo: 'bar'}, meta: {}})

      subject.remote_stuff.foo.should == 'bar'
    end

    it "handles metadata with a collection" do
      respond_with({remote_stuff: [{id: 2, foo: 'first'}, {id: 3, foo: 'second'}], meta: {}})

      subject.remote_stuff.first.foo.should == 'first'
      subject.remote_stuff.last.foo.should == 'second'
    end

    it "returns data from the attributes if that already exists" do
      subject.attributes[:remote_stuff] = 'wibble'

      subject.remote_stuff.should == 'wibble'
    end

  end

end
