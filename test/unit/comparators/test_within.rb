require 'helper'

class UnitTests::TestWithin < Test::Unit::TestCase
  def self.const_missing(name)
    if Linkage::Comparators.const_defined?(name)
      Linkage::Comparators.const_get(name)
    else
      super
    end
  end

  test "subclass of Binary" do
    assert_equal Linkage::Comparators::Binary, Within.superclass
  end

  test "valid parameters" do
    meta_object_1 = stub('meta object', :name => :foo, :side => :lhs, :ruby_type => { :type => Integer }, :static? => false)
    meta_object_2 = stub('meta object', :object => 123, :ruby_type => { :type => Fixnum }, :static? => true, :object => 123)
    meta_object_3 = stub('meta object', :name => :bar, :side => :rhs, :ruby_type => { :type => Integer }, :static? => false)
    assert_nothing_raised do
      Within.new(meta_object_1, meta_object_2, meta_object_3)
    end
  end

  test "score" do
    meta_object_1 = stub('meta object', :name => :foo, :side => :lhs, :ruby_type => { :type => Integer }, :static? => false)
    meta_object_2 = stub('meta object', :object => 123, :ruby_type => { :type => Fixnum }, :static? => true, :object => 123)
    meta_object_3 = stub('meta object', :name => :bar, :side => :rhs, :ruby_type => { :type => Integer }, :static? => false)
    comp = Within.new(meta_object_1, meta_object_2, meta_object_3)
    assert_equal 1, comp.score({:foo => 123}, {:bar => 124})
    assert_equal 1, comp.score({:foo => 124}, {:bar => 123})
    assert_equal 1, comp.score({:foo => 0}, {:bar => 123})
    assert_equal 0, comp.score({:foo => 0}, {:bar => 124})
  end

  test "registers itself" do
    assert_equal Within, Linkage::Comparator['within']
  end

  test "requires argument from each side" do
    meta_object_1 = stub('meta object', :name => :foo, :side => :lhs, :ruby_type => { :type => Integer }, :static? => false)
    meta_object_2 = stub('meta object', :object => 123, :ruby_type => { :type => Fixnum }, :static? => true, :object => 123)
    meta_object_3 = stub('meta object', :name => :bar, :side => :lhs, :ruby_type => { :type => Integer }, :static? => false)
    assert_raises do
      Within.new(meta_object_1, meta_object_2, meta_object_3)
    end
  end

  test "requires that 3rd argument has the same type as the first argument" do
    meta_object_1 = stub('meta object', :name => :foo, :side => :lhs, :ruby_type => { :type => Integer }, :static? => false)
    meta_object_2 = stub('meta object', :object => 123, :ruby_type => { :type => Fixnum }, :static? => true, :object => 123)
    meta_object_3 = stub('meta object', :name => :bar, :side => :rhs, :ruby_type => { :type => Date }, :static? => false)
    assert_raises do
      Within.new(meta_object_1, meta_object_2, meta_object_3)
    end
  end
end
