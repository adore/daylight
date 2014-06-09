require 'spec_helper'

describe VersionedUrlFor do

  class VersionedModelTest
    attr_accessor :to_param
    def initialize(id)
      @to_param = id
    end

    def to_model
      self
    end
  end

  module API
    module V1
      class TestVersionsController < ActionController::Base
        include VersionedUrlFor

        def api_v1_test_version_path model
          "/v1/test/#{model.to_param}"
        end
      end
    end
  end

  let(:controller) { API::V1::TestVersionsController.new }
  let(:model)      { VersionedModelTest.new(1) }


  it 'defines versioned name / path based on controller name' do
    controller.send(:versioned_name).should == 'api_v1_test_version'
    controller.send(:versioned_path).should == 'api_v1_test_version_path'
  end

  it 'uses overriden url_for for models' do
    controller.send(:versioned_url_for, model).should == '/v1/test/1'
    controller.send(:url_for, model).should ==  '/v1/test/1'
  end

  it 'uses regular url_for if not a model' do
    controller.should_receive(:url_for).with(action: 'foo').and_return('/path')
    controller.send(:url_for, action: 'foo').should ==  '/path'
  end
end
