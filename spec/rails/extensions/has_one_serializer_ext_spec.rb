require 'spec_helper'

class HasOneSerializerTest < ActiveRecord::Base
  belongs_to :associated_test
  has_one    :associated_through_test, through: :associated_test
end

class AssociatedTest < ActiveRecord::Base
  belongs_to :associated_through_test
end

class AssociatedThroughTest < ActiveRecord::Base
end

class HasOneSerializerTestController < ActionController::Base
  # The read_only values will be activated based on Serializer
  def show
    render json: HasOneSerializerTest.find(params[:id])
  end

  def embed
    render json: HasOneSerializerTest.find(params[:id]),
           serializer: EmbedHasOneSerializerTestSerializer
  end
end

class HasOneSerializerTestSerializer < ActiveModel::Serializer
  embed :ids

  has_one :associated_test                                      # tests orginal
  has_one :associated_through_test, through: :associated_test   # tests through
end

class EmbedHasOneSerializerTestSerializer < ActiveModel::Serializer
  has_one :associated_test                                      # tests orginal
  has_one :associated_through_test, through: :associated_test   # tests through
end

describe HasOneSerializerExt, type: [:controller, :routing] do

  def self.controller_class
    HasOneSerializerTestController
  end

  migrate do
    create_table :has_one_serializer_tests do |t|
      t.integer :associated_test_id
    end

    create_table :associated_tests do |t|
      t.integer :associated_through_test_id
    end

    create_table :associated_through_tests do |t|
      t.string :name
    end
  end

  before do
    @routes.draw do
      resources :has_one_serializer_test do
        get 'embed', on: :member
      end
    end
  end

  before :all do
    FactoryGirl.define do
      factory :has_one_serializer_test do
        associated_test
      end

      factory :associated_test do
        associated_through_test
      end

      factory :associated_through_test do
        name { Faker::Name.name }
      end
    end
  end

  after :all do
    Rails.application.reload_routes!
  end

  let!(:record) { create(:has_one_serializer_test) }

  #
  # embed id
  #

  it 'includes association id' do
    get :show, id: record.id

    json = JSON.parse(response.body)['has_one_serializer_test']
    json['associated_test_id'].should == record.associated_test_id
    json.keys.should_not include('associated_through_test_id')
  end

  it 'includes through association hash with ids' do
    get :show, id: record.id

    json = JSON.parse(response.body)['has_one_serializer_test']
    json['associated_test_attributes'].should == {
      'id'                         => record.associated_test.id,
      'associated_through_test_id' => record.associated_test.associated_through_test_id
    }
  end

  #
  # embed object
  #

  it 'includes association' do
    get :embed, id: record.id

    json = JSON.parse(response.body)['embed_has_one_serializer_test']
    json['associated_test'].should == record.associated_test.attributes
  end

  it 'includes association hash' do
    get :embed, id: record.id

    json = JSON.parse(response.body)['embed_has_one_serializer_test']
    json['associated_test_attributes'].should == {
      'id'                                 => record.associated_test.id,
      'associated_through_test_id'         => record.associated_test.associated_through_test_id,
      'associated_through_test_attributes' => {
        'id'   => record.associated_test.associated_through_test.id,
        'name' => record.associated_test.associated_through_test.name,
      }
    }
  end
end
