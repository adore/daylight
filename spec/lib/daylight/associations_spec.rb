require 'spec_helper'

describe Daylight::Associations do

  class RelatedTestClass < Daylight::API
    self.include_format_in_path = false
  end

  class AssociationsTestClass < Daylight::API
    self.include_format_in_path = false

    has_many   :related_test_classes
    has_many   :things,        class_name: 'RelatedTestClass'
    belongs_to :parent,        class_name: 'RelatedTestClass'
    has_one    :grandparent,   class_name: 'RelatedTestClass', through: :parent
    has_one    :associate,     class_name: 'RelatedTestClass'
    remote     :remote_stuff,  class_name: 'RelatedTestClass'

    def id;        123; end
    def parent_id; 456; end
  end

  class AnotherAssociationTestClass < Daylight::API
    belongs_to :parent, class_name: 'RelatedTestClass'
  end

  describe :has_many do

    before do
      data = [{name: 'one'}, {name: 'two'}]
      [RelatedTestClass, AssociationsTestClass].each do |clazz|
        stub_request(:get, %r{#{clazz.site}}).to_return(body: data.to_json)
      end
    end


    it "fetches the results out of the attributes if they exist" do
      object = AssociationsTestClass.first
      object.attributes['related_test_classes_attributes'] = ['yay']
      collection = object.related_test_classes
      collection.should be_instance_of(Array)
      collection.first.should == 'yay'
    end

    describe "with new resource" do
      let(:new_resource) { AssociationsTestClass.new }


      it "caches the results of the association" do
        collection = new_resource.related_test_classes
        new_resource.related_test_classes.should == collection
      end

      it "creates a method that construts an Array for the collection" do
        collection = new_resource.related_test_classes

        collection.should be_a Array
      end

      it "fetches the stored associations out of the attributes when they are set" do
        new_resource.related_test_classes = ["associated instances"]

        new_resource.related_test_classes.should == ["associated instances"]
      end
    end


    describe "with existing resource" do
      let(:existing_resource) { AssociationsTestClass.first }

      it "creates a method that construts an ResourceProxy for the association" do
        proxy = existing_resource.related_test_classes

        proxy.should be_a Daylight::ResourceProxy
        proxy.resource_class.should == RelatedTestClass
      end

      it "creates a method that construts an ResourceProxy with context about the association" do
        proxy = existing_resource.related_test_classes

        proxy.association_name.should == :related_test_classes
        proxy.association_resource.should == existing_resource
      end

      it "hits the association api endpoint" do
        existing_resource.related_test_classes.load

        a_request(:get, "http://daylight.test/v1/associations_test_classes/123/related_test_classes.json").should have_been_made
      end

      it "caches the results of the association" do
        proxy = existing_resource.related_test_classes
        existing_resource.related_test_classes.should == proxy
      end

      it "supports the :class_name option" do ## THIS ONE
        proxy = existing_resource.things
        proxy.resource_class.should == RelatedTestClass
      end

      it "chains using the proxy class for the associated model" do
        proxy = existing_resource.related_test_classes.where(wibble: 'wobble')

        proxy.resource_class.should == RelatedTestClass
        proxy.to_params[:filters].should == {wibble: 'wobble'}
      end

      it "fetches the stored associations out of the attributes when they exist" do
        existing_resource.related_test_classes = ["associated instances"]

        existing_resource.related_test_classes.should == ["associated instances"]
      end
    end
  end

  describe :belongs_to do

    before do
      data = { parent: {name: 'three'}}
      [RelatedTestClass, AssociationsTestClass].each do |clazz|
        stub_request(:get, %r{#{clazz.site}}).to_return(body: data.to_json)
      end
      stub_request(:get, %r{#{AnotherAssociationTestClass.site}}).to_return(body: { parent: data }.to_json)
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

    it 'fetches the parent object if no foreign key attr is present' do
      resource = AnotherAssociationTestClass.find(1)

      resource.parent.should_not be_nil
      resource.parent.name.should == 'three'
    end
  end

  describe :belongs_to_through do

    before do
      association_data = { through: {
          id: 1,
          parent_id: 456, # ignored because of parent_id method
          parent_attributes: {
            id: 456,
            name: 'nested',
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

      stub_request(:get, %r{#{AssociationsTestClass.element_path(1)}}).to_return(body: association_data.to_json)
      stub_request(:get, %r{#{AssociationsTestClass.element_path(2)}}).to_return(body: embedded_data.to_json)
      stub_request(:get, %r{#{RelatedTestClass.element_path(456)}}).to_return(body: related_data.merge(id: 456).to_json)
      stub_request(:get, %r{#{RelatedTestClass.element_path(3)}}).to_return(body: related_data.merge(id: 3).to_json)
    end

    it 'loads the parent object from the original response' do
      resource = AssociationsTestClass.find(1)

      resource.parent.should_not be_nil
      resource.parent.id.should   == 456
      resource.parent.name.should == 'nested'
    end

    it 'fetches the "through" object' do
      resource = AssociationsTestClass.find(1)

      resource.grandparent.should_not be_nil
      resource.grandparent.id.should   == 3
      resource.grandparent.name.should == 'related'
    end

    it 'fetches embedded "through" object' do
      resource = AssociationsTestClass.find(2)

      resource.grandparent.should be_kind_of(ActiveResource::Base)
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

  describe :has_one do
    before do
      associated = { id: nil, name: 'Hardy', associate_attributes: { id: 100 } }
      related    = { id: 100, name: 'Laurel' }
      stub_request(:get, %r{#{AssociationsTestClass.element_path(1)}}).to_return(body: associated.to_json)
      # It uses the filter method instead of default ActiveResource behavior
      # http://daylight.test/v1/related_test_classes?filters%5Bassociations_test_class_id%5D=123&limit=1
      stub_request(:get, %r{filters%5Bassociations_test_class_id%5D=123}).to_return(body: [related].to_json)
    end

    it 'still fetches the associate object' do
      resource = AssociationsTestClass.find(1)

      resource.associate.should_not be_nil
      resource.associate.id.should == 100
      resource.associate.name.should == 'Laurel'
    end

    it 'sets the associate to a new object' do
      resource = AssociationsTestClass.find(1)
      resource.associate = RelatedTestClass.new(name: 'Rik Mayall')

      resource.associate.name.should == 'Rik Mayall'
    end

    it 'sets the associate foreign key' do
      resource = AssociationsTestClass.find(1)
      resource.associate = RelatedTestClass.new(id: 333, name: 'Rik Mayall')

      resource.associate.associations_test_class_id.should == resource.id
    end
  end

  describe :remote do

    def respond_with(data)
      stub_request(:get, %r{#{AssociationsTestClass.site}}).to_return(body: data.to_json)
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
