require 'spec_helper'

class NoNestedAttributesTest < ActiveRecord::Base; end

# `inverse_of` and `accepts_nested_attributes_for` both need to be defined to
# test cyclic autosave problem that AutosaveAssociataionFix resolves
class NestedAttributeTest < ActiveRecord::Base
  has_many :collection, class_name: 'AssocNestedAttributeTest', inverse_of: :nested_attribute_test

  accepts_nested_attributes_for :collection
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
