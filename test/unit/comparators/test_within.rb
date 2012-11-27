require 'helper'

class UnitTests::TestWithin < Test::Unit::TestCase
  def self.const_missing(name)
    if Linkage::Comparators.const_defined?(name)
      Linkage::Comparators.const_get(name)
    else
      super
    end
  end

  test "subclass of Comparator" do
    assert_equal Linkage::Comparator, Within.superclass
  end

  test "valid parameters" do
    meta_object_1 = stub('meta object', :name => :foo, :ruby_type => { :type => Fixnum }, :static? => false)
    meta_object_2 = stub('meta object', :object => 123, :ruby_type => { :type => Fixnum }, :static? => true, :object => 123)
    meta_object_3 = stub('meta object', :name => :bar, :ruby_type => { :type => Fixnum }, :static? => false)
    assert_nothing_raised do
      Within.new(meta_object_1, meta_object_2, meta_object_3)
    end
  end

  test "score" do
    meta_object_1 = stub('meta object', :name => :foo, :ruby_type => { :type => Fixnum }, :static? => false)
    meta_object_2 = stub('meta object', :object => 123, :ruby_type => { :type => Fixnum }, :static? => true, :object => 123)
    meta_object_3 = stub('meta object', :name => :bar, :ruby_type => { :type => Fixnum }, :static? => false)
    comp = Within.new(meta_object_1, meta_object_2, meta_object_3)
    assert_equal 100, comp.score({:foo => 123}, {:bar => 124})
    assert_equal 100, comp.score({:foo => 124}, {:bar => 123})
    assert_equal 100, comp.score({:foo => 0}, {:bar => 123})
    assert_equal 0, comp.score({:foo => 0}, {:bar => 124})
  end
end
