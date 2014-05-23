require 'spec_helper'

describe Daylight::Helpers do
  class HelperTestClass
    include Daylight::Helpers

    attr_accessor :params

    def initialize params={}
      @params = params
    end
  end

  let(:helper) do
    HelperTestClass.new(scopes: %w[scope_a scope_b], filters: {attr_a: 'Foo', attr_b: 'Bar'}, order: 'name ASC', limit: '10', offset: '100')
  end

  it 'returns refiner params' do
    helper.scoped_params.should == %w[scope_a scope_b]
  end

  it 'returns filter params' do
    helper.filter_params.should == {attr_a: 'Foo', attr_b: 'Bar'}
  end

  it 'returns order params' do
    helper.order_params.should == 'name ASC'
  end

  it 'returns limit params' do
    helper.limit_params.should == '10'
  end

  it 'returns offset params' do
    helper.offset_params.should == 100
  end

  it 'raises an error if offset cannot be parsed as Integer' do
    expect { HelperTestClass.new(offset: 'a').offset_params }.to raise_error(ArgumentError, %q[invalid value for Integer(): "a"])
  end
end
