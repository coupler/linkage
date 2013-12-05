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

  test "score for not equal to" do
    field_1 = stub('foo field', :name => :foo, :ruby_type => { :type => Integer })
    field_2 = stub('bar field', :name => :bar, :ruby_type => { :type => Integer })
    comp = Compare.new([field_1], [field_2], :not_equal)
    assert_equal 1, comp.score({:foo => 10}, {:bar => 5})
    assert_equal 0, comp.score({:foo => 5}, {:bar => 5})
    assert_equal 1, comp.score({:foo => 0}, {:bar => 5})
  end

  test "score for greater than" do
    field_1 = stub('foo field', :name => :foo, :ruby_type => { :type => Integer })
    field_2 = stub('bar field', :name => :bar, :ruby_type => { :type => Integer })
    comp = Compare.new([field_1], [field_2], :greater_than)
    assert_equal 1, comp.score({:foo => 10}, {:bar => 5})
    assert_equal 0, comp.score({:foo => 5}, {:bar => 5})
    assert_equal 0, comp.score({:foo => 0}, {:bar => 5})
  end

  test "score for greater than or equal to" do
    field_1 = stub('foo field', :name => :foo, :ruby_type => { :type => Integer })
    field_2 = stub('bar field', :name => :bar, :ruby_type => { :type => Integer })
    comp = Compare.new([field_1], [field_2], :greater_than_or_equal_to)
    assert_equal 1, comp.score({:foo => 10}, {:bar => 5})
    assert_equal 1, comp.score({:foo => 5}, {:bar => 5})
    assert_equal 0, comp.score({:foo => 0}, {:bar => 5})
  end

  test "score for less than or equal to" do
    field_1 = stub('foo field', :name => :foo, :ruby_type => { :type => Integer })
    field_2 = stub('bar field', :name => :bar, :ruby_type => { :type => Integer })
    comp = Compare.new([field_1], [field_2], :less_than_or_equal_to)
    assert_equal 0, comp.score({:foo => 10}, {:bar => 5})
    assert_equal 1, comp.score({:foo => 5}, {:bar => 5})
    assert_equal 1, comp.score({:foo => 0}, {:bar => 5})
  end

  test "score for less than" do
    field_1 = stub('foo field', :name => :foo, :ruby_type => { :type => Integer })
    field_2 = stub('bar field', :name => :bar, :ruby_type => { :type => Integer })
    comp = Compare.new([field_1], [field_2], :less_than)
    assert_equal 0, comp.score({:foo => 10}, {:bar => 5})
    assert_equal 0, comp.score({:foo => 5}, {:bar => 5})
    assert_equal 1, comp.score({:foo => 0}, {:bar => 5})
  end

  test "score_datasets for equal to" do
    pend
  end

  test "registers itself" do
    assert_equal Compare, Linkage::Comparator['compare']
  end

  test "requires equal size sets" do
    field_1 = stub('foo field', :name => :foo, :ruby_type => { :type => Integer })
    field_2 = stub('bar field', :name => :bar, :ruby_type => { :type => Integer })
    assert_raises do
      Compare.new([field_1, field_2], [], :greater_than_or_equal_to)
    end
  end

  test "requires that sets have values with alike types" do
    field_1 = stub('foo field', :name => :foo, :ruby_type => { :type => Integer })
    field_2 = stub('bar field', :name => :bar, :ruby_type => { :type => Date })
    assert_raises do
      Compare.new([field_1], [field_2], :greater_than_or_equal_to)
    end
  end

  test "requires valid operation" do
    field_1 = stub('foo field', :name => :foo, :ruby_type => { :type => Integer })
    field_2 = stub('bar field', :name => :bar, :ruby_type => { :type => Integer })
    assert_raises do
      Compare.new([field_1], [field_2], 'foo')
    end
  end
end
