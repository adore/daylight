require 'spec_helper'

describe Daylight::Params do

  module HelperTest
    def helper_method
      params[:foo]
    end
  end

  class ParamsTestClass
    include Daylight::Params
  end

  let(:mixin) do
    ParamsTestClass.new
  end

  it 'has no params method' do
    mixin.should_not respond_to(:params)
  end

  describe :with_params do
    it 'can access params directly' do
      mixin.with_helper({foo: 'bar'}) do |helper|
        helper.params[:foo].should == 'bar'
      end
    end

    it 'can access params through helper methods' do
      Daylight::Params::HelperProxy.send(:include, HelperTest)
      mixin.with_helper({foo: 'baz'}) do |helper|
        helper.helper_method.should == 'baz'
      end
    end

    it 'still no params after accessed in context' do
      mixin.with_helper({foo: 'bar'}) do |helper|
        helper.params
      end

      mixin.should_not respond_to(:params)
    end
  end
end
