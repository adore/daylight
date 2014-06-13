require 'spec_helper'

class RefinerMockActiveRecordBase
  include Daylight::Refiners::Extension

  def self.scope(name, body, &block); end
  def self.where(*args); end
  def self.order(*args); end
  def self.reflections(*args); {} end
end

class RefinersTestClass < RefinerMockActiveRecordBase
  scope :scope_a, -> { 'a' }
  scope :scope_b, -> { 'b' }

  def self.find(id)
    RefinersTestClass.new
  end

  def foo
    123
  end
end

describe Daylight::Refiners::AttributeSeive do
  let(:valid_attribute_names) { %w[foo bar baz] }

  describe 'with invalid attributes' do
    let(:seive) do
      Daylight::Refiners::AttributeSeive.new(valid_attribute_names, %w[foo bar wibble])
    end

    it 'returns valid attributes' do
      seive.valid_attributes.should == %w[foo bar]
    end

    it 'returns invalid attributes' do
      seive.invalid_attributes.should == %w[wibble]
    end

    it 'returns false attributes_valid?' do
      seive.should_not be_attributes_valid
    end
  end

  it 'returns true when valid' do
    seive = Daylight::Refiners::AttributeSeive.new(valid_attribute_names, %w[foo bar])
    seive.should be_attributes_valid
  end


  it 'returns true when nil' do
    seive = Daylight::Refiners::AttributeSeive.new(valid_attribute_names, nil)
    seive.should be_attributes_valid
  end
end

describe Daylight::Refiners do
  it 'tracks registered scopes' do
    RefinersTestClass.registered_scopes.should == %w[scope_a scope_b]
  end

  it 'returns true if scoped? finds a match' do
    RefinersTestClass.should be_scoped(:scope_a)
    RefinersTestClass.should_not be_scoped(:foo)
  end

  describe :scope_by do
    let (:all) { double }

    before do
      RefinersTestClass.stub(all: all)
    end

    it 'raises an error an unknown scope is supplied' do
      expect { RefinersTestClass.scoped_by(:foo) }.to raise_error(ArgumentError, 'Unknown scope: foo')
    end

    it 'applies supplied scope' do
      all.should_receive(:scope_a)

      RefinersTestClass.scoped_by(:scope_a)
    end

    it 'applies supplied scope' do
      all.should_receive(:scope_a).and_return(all)
      all.should_receive(:scope_b).and_return(all)

      RefinersTestClass.scoped_by(%w[scope_a scope_b])
    end

    it 'applies no scope when nil is supplied' do
      RefinersTestClass.scoped_by(nil).should == all
    end
  end

  describe :filter_by do
    before do
      RefinersTestClass.stub(attribute_names: %w[foo bar])
    end

    it 'raises an error if an unknown attribute is supplied' do
      expect { RefinersTestClass.filter_by(baz: 'wibble') }.to raise_error(ArgumentError, 'Unknown key: baz')
    end

    it 'applies where clause for all supplied attributes' do
      RefinersTestClass.should_receive(:where).with({'foo' => 'baz', 'bar' => 'wibble'})

      RefinersTestClass.filter_by({foo: 'baz', bar: 'wibble'})
    end

    it 'applies where clause with no attributes (and will be discarded by rails)' do
      RefinersTestClass.should_receive(:where).with({})

      RefinersTestClass.filter_by(nil)
    end

    it 'allows reflection keys' do
      RefinersTestClass.stub(reflections: {boing: 'boing'})

      expect { RefinersTestClass.filter_by(boing: 'boing') }.to_not raise_error
    end
  end

  describe :order_by do
    before do
      RefinersTestClass.stub(attribute_names: %w[foo bar])
    end

    it 'raises an error if unknown attribute is supplied (as a String)' do
      expect { RefinersTestClass.order_by('baz') }.to raise_error(ArgumentError, 'Unknown attribute: baz')
      expect { RefinersTestClass.order_by('bar ASC, baz') }.to raise_error(ArgumentError, 'Unknown attribute: baz')
      expect { RefinersTestClass.order_by('bar, baz ASC') }.to raise_error(ArgumentError, 'Unknown attribute: baz')
      expect { RefinersTestClass.order_by('bar ASC, baz DESC') }.to raise_error(ArgumentError, 'Unknown attribute: baz')
    end

    it 'raises an error if unknown attribute is supplied (as an Array)' do
      expect { RefinersTestClass.order_by([:baz, :foo]) }.to raise_error(ArgumentError, 'Unknown attribute: baz')
    end

    it 'raises an error if unknown attribute is supplied (as a Hash)' do
      expect { RefinersTestClass.order_by({foo: 'asc', baz: 'asc', bar: 'desc'}) }.to raise_error(ArgumentError, 'Unknown attribute: baz')
    end

    it 'applies order clause for the supplied order' do
      RefinersTestClass.should_receive(:order).with(nil)

      RefinersTestClass.order_by(nil)
    end
  end

  describe :remoted_methods do
    it "keeps track of remoted methods" do
      RefinersTestClass.add_remoted(:foo)

      RefinersTestClass.remoted?(:foo).should be_true
      RefinersTestClass.remoted?(:not_a_remoted_method).should be_false

      RefinersTestClass.remoted_methods.should == [:foo]
    end
  end

  describe :remoted do
    before do
      RefinersTestClass.add_remoted(:foo)
    end

    it "raises an error if an unknown remoted is supplied" do
      expect { RefinersTestClass.remoted(id:1, remoted:'not_a_remoted_method') }.to raise_error(ArgumentError)
    end

    it "returns the remoted call data" do
      RefinersTestClass.remoted(id:1, remoted:'foo').should == 123
    end
  end
end

