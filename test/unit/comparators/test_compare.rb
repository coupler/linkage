require 'helper'

class UnitTests::TestCompare < Test::Unit::TestCase
  def self.const_missing(name)
    if Linkage::Comparators.const_defined?(name)
      Linkage::Comparators.const_get(name)
    else
      super
    end
  end

  test "subclass of Comparator" do
    assert_equal Linkage::Comparator, Compare.superclass
  end

  test "valid parameters" do
    meta_object_1 = stub('meta object', :name => :foo, :side => :lhs, :ruby_type => { :type => Integer }, :static? => false)
    meta_object_2 = stub('meta object', :object => '>', :ruby_type => { :type => String }, :static? => true, :raw? => true)
    meta_object_3 = stub('meta object', :name => :bar, :side => :rhs, :ruby_type => { :type => Integer }, :static? => false)
    assert_nothing_raised do
      Compare.new(meta_object_1, meta_object_2, meta_object_3)
    end
  end

  test "score for not equal to" do
    meta_object_1 = stub('meta object', :name => :foo, :side => :lhs, :ruby_type => { :type => Integer }, :static? => false)
    meta_object_2 = stub('meta object', :object => '!=', :ruby_type => { :type => String }, :static? => true, :raw? => true)
    meta_object_3 = stub('meta object', :name => :bar, :side => :rhs, :ruby_type => { :type => Integer }, :static? => false)
    comp = Compare.new(meta_object_1, meta_object_2, meta_object_3)
    assert_equal 1, comp.score({:foo => 10}, {:bar => 5})
    assert_equal 0, comp.score({:foo => 5}, {:bar => 5})
    assert_equal 1, comp.score({:foo => 0}, {:bar => 5})
  end

  test "score for greater than" do
    meta_object_1 = stub('meta object', :name => :foo, :side => :lhs, :ruby_type => { :type => Integer }, :static? => false)
    meta_object_2 = stub('meta object', :object => '>', :ruby_type => { :type => String }, :static? => true, :raw? => true)
    meta_object_3 = stub('meta object', :name => :bar, :side => :rhs, :ruby_type => { :type => Integer }, :static? => false)
    comp = Compare.new(meta_object_1, meta_object_2, meta_object_3)
    assert_equal 1, comp.score({:foo => 10}, {:bar => 5})
    assert_equal 0, comp.score({:foo => 5}, {:bar => 5})
    assert_equal 0, comp.score({:foo => 0}, {:bar => 5})
  end

  test "score for greater than or equal to" do
    meta_object_1 = stub('meta object', :name => :foo, :side => :lhs, :ruby_type => { :type => Integer }, :static? => false)
    meta_object_2 = stub('meta object', :object => '>=', :ruby_type => { :type => String }, :static? => true, :raw? => true)
    meta_object_3 = stub('meta object', :name => :bar, :side => :rhs, :ruby_type => { :type => Integer }, :static? => false)
    comp = Compare.new(meta_object_1, meta_object_2, meta_object_3)
    assert_equal 1, comp.score({:foo => 10}, {:bar => 5})
    assert_equal 1, comp.score({:foo => 5}, {:bar => 5})
    assert_equal 0, comp.score({:foo => 0}, {:bar => 5})
  end

  test "score for less than or equal to" do
    meta_object_1 = stub('meta object', :name => :foo, :side => :lhs, :ruby_type => { :type => Integer }, :static? => false)
    meta_object_2 = stub('meta object', :object => '<=', :ruby_type => { :type => String }, :static? => true, :raw? => true)
    meta_object_3 = stub('meta object', :name => :bar, :side => :rhs, :ruby_type => { :type => Integer }, :static? => false)
    comp = Compare.new(meta_object_1, meta_object_2, meta_object_3)
    assert_equal 0, comp.score({:foo => 10}, {:bar => 5})
    assert_equal 1, comp.score({:foo => 5}, {:bar => 5})
    assert_equal 1, comp.score({:foo => 0}, {:bar => 5})
  end

  test "score for less than" do
    meta_object_1 = stub('meta object', :name => :foo, :side => :lhs, :ruby_type => { :type => Integer }, :static? => false)
    meta_object_2 = stub('meta object', :object => '<', :ruby_type => { :type => String }, :static? => true, :raw? => true)
    meta_object_3 = stub('meta object', :name => :bar, :side => :rhs, :ruby_type => { :type => Integer }, :static? => false)
    comp = Compare.new(meta_object_1, meta_object_2, meta_object_3)
    assert_equal 0, comp.score({:foo => 10}, {:bar => 5})
    assert_equal 0, comp.score({:foo => 5}, {:bar => 5})
    assert_equal 1, comp.score({:foo => 0}, {:bar => 5})
  end

  test "registers itself" do
    assert_equal Compare, Linkage::Comparator['compare']
  end

  test "requires argument from each side" do
    meta_object_1 = stub('meta object', :name => :foo, :side => :lhs, :ruby_type => { :type => Integer }, :static? => false)
    meta_object_2 = stub('meta object', :object => '>=', :ruby_type => { :type => String }, :static? => true, :raw? => true)
    meta_object_3 = stub('meta object', :name => :bar, :side => :lhs, :ruby_type => { :type => Integer }, :static? => false)
    assert_raises do
      Compare.new(meta_object_1, meta_object_2, meta_object_3)
    end
  end

  test "requires that 3rd argument has the same type as the first argument" do
    meta_object_1 = stub('meta object', :name => :foo, :side => :lhs, :ruby_type => { :type => Integer }, :static? => false)
    meta_object_2 = stub('meta object', :object => '>=', :ruby_type => { :type => String }, :static? => true, :raw? => true)
    meta_object_3 = stub('meta object', :name => :bar, :side => :rhs, :ruby_type => { :type => Date }, :static? => false)
    assert_raises do
      Compare.new(meta_object_1, meta_object_2, meta_object_3)
    end
  end

  test "requires raw operator to be >, >=, <=, <, or !=" do
    meta_object_1 = stub('meta object', :name => :foo, :side => :lhs, :ruby_type => { :type => Integer }, :static? => false)
    meta_object_2 = stub('meta object', :object => 'foo', :ruby_type => { :type => String }, :static? => true, :raw? => true)
    meta_object_3 = stub('meta object', :name => :bar, :side => :rhs, :ruby_type => { :type => Integer }, :static? => false)
    assert_raises do
      Compare.new(meta_object_1, meta_object_2, meta_object_3)
    end
  end
end
