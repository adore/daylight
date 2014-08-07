require 'spec_helper'

class NoNestedAttributesTest < ActiveRecord::Base; end

# `inverse_of` and `accepts_nested_attributes_for` both need to be defined to
# test cyclic autosave problem that AutosaveAssociataionFix resolves
class NestedAttributeTest < ActiveRecord::Base
  has_many :collection, class_name: 'AssocNestedAttributeTest', inverse_of: :nested_attribute_test
  has_many :through_collection, class_name: 'SingleNestedAttributeTest', through: :collection, source: :single_nested_attribute_test

  accepts_nested_attributes_for :collection, :through_collection
end

class SingleNestedAttributeTest < ActiveRecord::Base
  has_one :single, class_name: 'AssocNestedAttributeTest', inverse_of: :single_nested_attribute_test

  accepts_nested_attributes_for :single, allow_destroy: true # with options
end

class AssocNestedAttributeTest < ActiveRecord::Base
  belongs_to :nested_attribute_test, inverse_of: :collection
  belongs_to :single_nested_attribute_test, inverse_of: :single

  accepts_nested_attributes_for :nested_attribute_test, :single_nested_attribute_test
end

class HabtmParentNestedAttributeTest < ActiveRecord::Base
  has_and_belongs_to_many :foo, class_name: 'HabtmChildNestedAttributeTest'

  accepts_nested_attributes_for :foo
end

class HabtmChildNestedAttributeTest < ActiveRecord::Base
  has_and_belongs_to_many :foo, class_name: 'HabtmParentNestedAttributeTest'
end

describe NestedAttributesExt, type: [:model] do

  migrate do
    create_table :nested_attribute_tests do |t|
      t.string :name
    end

    create_table :single_nested_attribute_tests do |t|
      t.string :name
    end

    create_table :assoc_nested_attribute_tests do |t|
      t.string     :name
      t.references :nested_attribute_test
      t.references :single_nested_attribute_test
    end

    create_table :habtm_parent_nested_attribute_tests do |t|
      t.string :name
    end

    create_table :habtm_child_nested_attribute_tests do |t|
      t.string :name
    end

    create_table :habtm_child_nested_attribute_tests_parent_nested_attribute_tests do |t|
      t.belongs_to :habtm_parent_nested_attribute_test
      t.belongs_to :habtm_child_nested_attribute_test
    end
  end

  before(:all) do
    FactoryGirl.define do
      factory :nested_attribute_test do
        name { Faker::Name.name }
      end

      factory :single_nested_attribute_test do
        name { Faker::Name.name }
      end

      factory :assoc_nested_attribute_test do
        name { Faker::Name.name }
      end

      factory :habtm_child_nested_attribute_test do
        name { Faker::Name.name }
      end

      factory :habtm_parent_nested_attribute_test do
        name { Faker::Name.name }
      end
    end
  end

  describe 'nested_resource_names' do
    it 'has empty array of no nested resources are configured' do
      NoNestedAttributesTest.nested_resource_names.should == []
      NoNestedAttributesTest.nested_resource_names.should be_frozen
    end

    it 'stores only nested resource names' do
      SingleNestedAttributeTest.nested_resource_names.should == [:single]
      SingleNestedAttributeTest.nested_resource_names.should be_frozen

      AssocNestedAttributeTest.nested_resource_names.should == [:nested_attribute_test, :single_nested_attribute_test]
      AssocNestedAttributeTest.nested_resource_names.should be_frozen
    end

    it 'propogates and updates nested attribute options' do
      SingleNestedAttributeTest.nested_attributes_options.should == {single: {allow_destroy: true, update_only: false}}
    end
  end


  describe 'associate' do

    describe 'has_many' do
      let(:record) { create(:nested_attribute_test) }
      let(:member) { create(:assoc_nested_attribute_test) }

      it "ignores nil values" do
        record.collection_attributes = nil

        lambda { record.save! }.should_not raise_error
        record.collection.should == []
      end

      it "continues to create and associate new records" do
        record.collection_attributes = [{name: 'foo'}, {name: 'bar'}]

        lambda { record.save! }.should_not raise_error

        names = record.collection.map(&:name)
        names.should include('foo')
        names.should include('bar')
      end

      it "continues to update assoicated records" do
        record.collection << member
        record.collection_attributes = [{id: member.id, name: 'Foozle Cumberbunch'}]

        lambda { record.save! }.should_not raise_error
        record.collection.size.should == 1
        record.collection.first.name.should == 'Foozle Cumberbunch'
      end

      # this also tests cyclic autosave problem that AutosaveAssociataionFix resolves
      it "associates existing records" do
        record.collection_attributes = [{id: member.id}]

        lambda { record.save! }.should_not raise_error
        record.collection.size.should == 1
        record.collection.first.id.should == member.id
      end

      # this also tests cyclic autosave problem that AutosaveAssociataionFix resolves
      it "keeps association for existing records that are already assoicated" do
        record.collection << member
        record.collection_attributes = [{id: member.id}]

        lambda { record.save! }.should_not raise_error
        record.collection.size.should == 1
        record.collection.first.id.should == member.id
      end

      it "updates records that were just associated" do
        record.collection_attributes = [{id: member.id, name: 'Foozle Cumberbunch'}]

        lambda { record.save! }.should_not raise_error
        record.collection.size.should == 1
        record.collection.first.name.should == 'Foozle Cumberbunch'
      end

      it "ignores foreign key updates" do
        different_foreign_key = record.id + 1
        record.collection_attributes = [{id: member.id, name: 'Foozle Cumberbunch', nested_attribute_test_id: different_foreign_key}]

        lambda { record.save! }.should_not raise_error

        record.collection.size.should == 1
        record.collection.first.nested_attribute_test_id.should == record.id
      end

      # this also tests cyclic autosave problem that AutosaveAssociataionFix resolves
      it "updates previsoulsy associated records" do
        record.collection << member

        lambda { record.update!(collection_attributes: [{id: member.id, name: 'Foozle Cumberbunch'}]) }.should_not raise_error

        record.collection.size.should == 1
        record.collection.first.name.should == 'Foozle Cumberbunch'
      end
    end

    describe 'has_one' do
      let(:record) { create(:single_nested_attribute_test) }
      let(:member) { create(:assoc_nested_attribute_test) }

      it "ignores nil values" do
        record.single = nil

        lambda { record.save! }.should_not raise_error
        record.single.should be_nil
      end

      it "continues to create and associate new records" do
        record.single_attributes = {name: 'wibble'}

        lambda { record.save! }.should_not raise_error

        record.single.name.should == 'wibble'
      end
    end
  end

  describe 'unassociating records missing from the attributes collection' do

    let(:single1) { create(:single_nested_attribute_test) }
    let(:single2) { create(:single_nested_attribute_test) }
    let(:assoc1) do
      create(:assoc_nested_attribute_test) {|record| record.single_nested_attribute_test = single1 }
    end
    let(:assoc2) do
      create(:assoc_nested_attribute_test) {|record| record.single_nested_attribute_test = single2 }
    end

    let(:record) do
      record = create(:nested_attribute_test) {|r| r.collection = [assoc1, assoc2] }
    end

    it 'handles has_many relationships' do
      record.collection_attributes = [assoc2.as_json]

      lambda { record.save! }.should_not raise_error

      record.reload.collection.map(&:id).should == [assoc2.id]

      assoc1.reload.nested_attribute_test.should be_nil
      assoc2.reload.nested_attribute_test.should == record
    end

    it 'ignores has_many through' do
      assoc2.single_nested_attribute_test.id.should == single2.id

      record.through_collection.count.should == 2

      record.through_collection_attributes = [single1.as_json]

      lambda { record.save! }.should_not raise_error

      record.reload.through_collection.count.should == 2
    end

    it 'ignores habtm' do
      test = create(:habtm_parent_nested_attribute_test)
      test.foo << create(:habtm_child_nested_attribute_test)
      test.foo << create(:habtm_child_nested_attribute_test)
      test.save!

      test.reload.foo.count.should == 2

      test.foo_attributes = [test.foo.first.as_json]

      lambda { record.save! }.should_not raise_error

      test.reload.foo.count.should == 2
    end

    it 'allows removing all things from a collection'

  end

end
