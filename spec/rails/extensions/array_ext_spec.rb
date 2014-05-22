require 'spec_helper'

class NonExtractableTest < Hash; end

class IsExtractableTest < Hash
  def extractable_options?
    true
  end
end

describe Array do
  describe :extract_options do
    it 'returns options' do
      [foo: 'bar'].extract_options.should == {foo: 'bar'}
      ['a', foo: 'bar'].extract_options.should == {foo: 'bar'}
    end

    it 'returns empty hash when no options' do
      [].extract_options.should == {}
      ['a', 'b'].extract_options.should == {}
    end

    it 'returns empty hash when not extractable' do
      hash = NonExtractableTest.new
      hash[:foo] = 'bar'
      [hash].extract_options.should == {}
    end

    it 'returns extractable hash when extractable' do
      test = IsExtractableTest.new
      test[:foo] = 'bar'
      [test].extract_options.should == test
    end

    it 'leaves options on arguments' do
      hash = [foo: 'bar']
      hash.extract_options
      hash.should ==  [foo: 'bar']

      hash = ['a', foo: 'bar']
      hash.extract_options
      hash.should ==  ['a', foo: 'bar']

      test = IsExtractableTest.new
      test[:foo] = 'bar'
      hash = [test]
      hash.extract_options
      hash.should == [test]
    end
  end
end