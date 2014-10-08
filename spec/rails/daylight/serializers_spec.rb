require 'spec_helper'

describe Daylight::Serializers do

  class SerializerTest < ActiveRecord::Base
    belongs_to :serializer_test_with_custom
    has_one :single, class_name: 'SerializerTestWithCustom', foreign_key: :another_id
    has_one :serializer_through_test, through: :serializer_test_with_custom
  end

  class SerializerTestWithCustom < ActiveRecord::Base
    has_many :serializer_test
    has_one :serializer_through_test
    def active_model_serializer
      TestCustomSerializer
    end
  end

  class SerializerThroughTest < ActiveRecord::Base
  end

  class TestCustomSerializer < ActiveModel::Serializer ; end

  migrate do
    create_table :serializer_tests do |t|
      t.string  :name
      t.integer :serializer_test_with_custom_id
    end

    create_table :serializer_test_with_customs do |t|
      t.string :name
      t.integer :another_id
      t.integer :serializer_through_test_id
    end

    create_table :serializer_through_tests do |t|
      t.string :name
      t.integer :serializer_test_with_custom_id
    end
  end

  before do
    SerializerTest.create(
      name: 'parent',
      serializer_test_with_custom: SerializerTestWithCustom.create(name: 'one', serializer_through_test: SerializerThroughTest.create(name: 'through')),
      single: SerializerTestWithCustom.create(name: 'two')
    )
  end

  let(:model) { SerializerTest.first }
  let(:json)  { model.active_model_serializer.new(model).as_json }

  it "defines a default serializer" do
    SerializerTest.new.active_model_serializer.ancestors.should include(ActiveModel::Serializer)
  end

  it "allows custom serializers" do
    SerializerTestWithCustom.new.active_model_serializer.should == TestCustomSerializer
  end

  it "handles custom ids" do
    json[:another_id].should be_present
  end

  it "includes attributes" do
    json[:name].should == 'parent'
  end

  it "sets up has_one relationships" do
    json[:serializer_test_with_custom_id].should == model.serializer_test_with_custom.id
  end

  it "correctly handles has_one through relationships" do
    json[:serializer_test_with_custom_attributes][:serializer_through_test_id].should ==
      model.serializer_test_with_custom.serializer_through_test.id
  end

  it "correctly reports the model class" do
    model.active_model_serializer.model_class.should == SerializerTest
  end
end
