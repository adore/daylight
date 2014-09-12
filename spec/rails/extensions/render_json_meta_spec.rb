require 'spec_helper'

class AssociatedRenderJsonMetaTest < ActiveRecord::Base
end

class RenderJsonMetaTest < ActiveRecord::Base
  has_many :children, class_name: 'AssociatedRenderJsonMetaTest'

  accepts_nested_attributes_for :children
end

# this implicitly tests read_only attributes
class RenderJsonMetaTestSerializer < ActiveModel::Serializer
  read_only :name, :valid?

  def valid?; true; end
end

class RenderJsonMetaTestController < ActionController::Base
  # The read_only values will be activated based on Serializer
  def index
    render json: RenderJsonMetaTest.all
  end

  def show
    render json: RenderJsonMetaTest.find(params[:id])
  end

  # AssociatonRelation will activate where_values
  def associated
    render json: RenderJsonMetaTest.find(params[:id]).children.where(name: params[:name])
  end

  def child
    render json: AssociatedRenderJsonMetaTest.find(params[:id])
  end
end

describe RenderJsonMeta, type: [:controller, :routing] do

  def self.controller_class
    RenderJsonMetaTestController
  end

  migrate do
    create_table :render_json_meta_tests do |t|
      t.string  :name
    end

    create_table :associated_render_json_meta_tests do |t|
      t.string  :name
      t.integer :render_json_meta_test_id
    end
  end

  before do
    @routes.draw do
      resources :render_json_meta_test do
        get 'associated', on: :member
        get 'child',      on: :member
      end
    end
  end

  before :all do
    FactoryGirl.define do
      factory :render_json_meta_test do
        name { Faker::Name.name }
      end

      factory :associated_render_json_meta_test do
        name { Faker::Name.name }
      end
    end
  end

  after :all do
    Rails.application.reload_routes!
  end

  let!(:record1)    { create(:render_json_meta_test) }
  let!(:record2)    { create(:render_json_meta_test) }
  let!(:associated) { create(:associated_render_json_meta_test, render_json_meta_test_id: record1.id) }

  describe "read_only" do
    it 'renders on record' do
      get :show, id: record1.id

      # tests for no '?' on valid in both the attribute and read_only names
      json = JSON.parse(response.body)
      json['render_json_meta_test'].keys.should include('valid')
      json['meta']['render_json_meta_test'].should include({'read_only' => ['name', 'valid']})
    end

    it 'renders on collection' do
      get :index

      json = JSON.parse(response.body)
      json['meta']['render_json_meta_test'].should include({'read_only' => ['name', 'valid'] })
    end

    it 'renders no metadata' do
      get :child, id: associated.id

      json = JSON.parse(response.body)
      json.keys.should_not include('meta')
    end
  end

  describe "nested_resources" do
    it 'renders on record' do
      get :show, id: record1.id

      # tests for no '?' on valid in both the attribute and read_only names
      json = JSON.parse(response.body)
      json['meta']['render_json_meta_test'].should include({'nested_resources' => ['children']})
    end

    it 'renders on collection' do
      get :index

      json = JSON.parse(response.body)
      json['meta']['render_json_meta_test'].should include({'nested_resources' => ['children']})
    end

    it 'renders no metadata' do
      get :child, id: associated.id

      json = JSON.parse(response.body)
      json.keys.should_not include('meta')
    end
  end

  it 'renders where_values' do
    get :associated, id: record1.id, name: associated.name

    json = JSON.parse(response.body)
    json['meta']['where_values'].should == {'render_json_meta_test_id' => associated.render_json_meta_test_id , 'name' => associated.name }
  end
end
