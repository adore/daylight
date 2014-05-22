require 'spec_helper'

class OrMethodsTest < ActiveRecord::Base
  scope :ready,   -> { where(ready: true) }
  scope :willing, -> { where(status: 'willing') }
end

describe OrMethods, type: [:model] do

  migrate do
    create_table :or_methods_tests do |t|
      t.string  'status'
      t.boolean 'ready'
    end
  end

  before(:all) do
    FactoryGirl.define do
      factory :or_methods_test do
      end
    end
  end

  before do
    create :or_methods_test, id: 1, ready: true,  status: 'running'
    create :or_methods_test, id: 2, ready: false, status: 'stopped'
    create :or_methods_test, id: 3, ready: false, status: 'starting'
    create :or_methods_test, id: 4, ready: false, status: 'willing'
    create :or_methods_test, id: 5, ready: false, status: 'running'
  end

  it 'merges results from two where clauses' do
    results = OrMethodsTest.where(status: 'running').or.where(status: 'stopped')

    results.size.should == 3
    ids = results.map(&:id)
    ids.should include(1)
    ids.should include(2)
    ids.should include(5)
  end

  it 'merges results from two where clauses (transverse)' do
    results = OrMethodsTest.where(status: 'stopped').or.where(status: 'running')

    results.size.should == 3
    ids = results.map(&:id)
    ids.should include(1)
    ids.should include(2)
    ids.should include(5)
  end

  it 'merges results from a where clause and an or clause' do
    results = OrMethodsTest.where(status: 'running').or(status: 'stopped')

    results.size.should == 3
    ids = results.map(&:id)
    ids.should include(1)
    ids.should include(2)
    ids.should include(5)
  end

  it 'merges results from a where clause and an or clause (transverse)' do
    results = OrMethodsTest.where(status: 'stopped').or(status: 'running')

    results.size.should == 3
    ids = results.map(&:id)
    ids.should include(1)
    ids.should include(2)
    ids.should include(5)
  end

  it 'merges results from where clause and named scope' do
    results = OrMethodsTest.where(status: 'starting').or.ready

    results.size.should == 2
    ids = results.map(&:id)
    ids.should include(1)
    ids.should include(3)
  end

  it 'merges results from where clause and named scope (transverse)' do
    results = OrMethodsTest.ready.or.where(status: 'starting')

    results.size.should == 2
    ids = results.map(&:id)
    ids.should include(1)
    ids.should include(3)
  end

  it 'merges results from two named scopes' do
    results = OrMethodsTest.ready.or.willing

    results.size.should == 2
    ids = results.map(&:id)
    ids.should include(1)
    ids.should include(4)
  end

  it 'merges results from two named scopes (transverse)' do
    results = OrMethodsTest.willing.or.ready

    results.size.should == 2
    ids = results.map(&:id)
    ids.should include(1)
    ids.should include(4)
  end

  it 'merges the results of two sql literals' do
    results = OrMethodsTest.where("status = ?", 'running').or.where("status = ?", 'stopped')

    results.size.should == 3
    ids = results.map(&:id)
    ids.should include(1)
    ids.should include(2)
    ids.should include(5)
  end

  it 'merges the results of two sql literals (transverse)' do
    results = OrMethodsTest.where("status = ?", 'stopped').or.where("status = ?", 'running')

    results.size.should == 3
    ids = results.map(&:id)
    ids.should include(1)
    ids.should include(2)
    ids.should include(5)
  end

  it 'merges the results of an sql literal and an or clause' do
    results = OrMethodsTest.where(ready: true).or("status = ?", 'stopped')

    results.size.should == 2
    ids = results.map(&:id)
    ids.should include(1)
    ids.should include(2)
  end

  it 'merges the results of an sql literal and an or clause (transverse)' do
    results = OrMethodsTest.where("status = ?", 'stopped').or(ready: true)

    results.size.should == 2
    ids = results.map(&:id)
    ids.should include(1)
    ids.should include(2)
  end

  it 'merges the results of an sql literal and a scope' do
    results = OrMethodsTest.ready.or("status = ?", 'stopped')

    results.size.should == 2
    ids = results.map(&:id)
    ids.should include(1)
    ids.should include(2)
  end

  it 'merges the results of an sql literal and a scope (transverse)' do
    results = OrMethodsTest.where("status = ?", 'stopped').or.ready

    results.size.should == 2
    ids = results.map(&:id)
    ids.should include(1)
    ids.should include(2)
  end

  it 'merges the results of a not clause with an or clause' do
    results = OrMethodsTest.where.not(status: 'running').or(ready: true)

    results.size.should == 4
    ids = results.map(&:id)
    ids.should include(1)
    ids.should include(2)
    ids.should include(3)
    ids.should include(4)
  end

  it 'merges the results of a not clause with an or clause (transverse)' do
    results = OrMethodsTest.where(ready: true).or.not(status: 'running')

    results.size.should == 4
    ids = results.map(&:id)
    ids.should include(1)
    ids.should include(2)
    ids.should include(3)
    ids.should include(4)
  end

  it 'merges the results of a not clause with a named scope' do
    results = OrMethodsTest.where.not(status: 'running').or.ready

    results.size.should == 4
    ids = results.map(&:id)
    ids.should include(1)
    ids.should include(2)
    ids.should include(3)
    ids.should include(4)
  end

  it 'merges the results of a not clause with a named scope (transverse)' do
    results = OrMethodsTest.ready.or.not(status: 'running')

    results.size.should == 4
    ids = results.map(&:id)
    ids.should include(1)
    ids.should include(2)
    ids.should include(3)
    ids.should include(4)
  end

  it 'merges the results of a not sql literal with an or clause' do
    results = OrMethodsTest.where.not('status = ?', 'running').or(ready: true)

    results.size.should == 4
    ids = results.map(&:id)
    ids.should include(1)
    ids.should include(2)
    ids.should include(3)
    ids.should include(4)
  end

  it 'merges the results of a not clause with an or clause (transverse)' do
    results = OrMethodsTest.where(ready: true).or.not('status = ?', 'running')

    results.size.should == 4
    ids = results.map(&:id)
    ids.should include(1)
    ids.should include(2)
    ids.should include(3)
    ids.should include(4)
  end

  it 'merges the results of a not sql literal with a named scope' do
    results = OrMethodsTest.where.not('status = ?', 'running').or.ready

    results.size.should == 4
    ids = results.map(&:id)
    ids.should include(1)
    ids.should include(2)
    ids.should include(3)
    ids.should include(4)
  end

  it 'merges the results of a not sql literal with a named scope (transverse)' do
    results = OrMethodsTest.ready.or.not('status = ?', 'running')

    results.size.should == 4
    ids = results.map(&:id)
    ids.should include(1)
    ids.should include(2)
    ids.should include(3)
    ids.should include(4)
  end
end