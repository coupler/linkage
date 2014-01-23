require File.expand_path("../../test_comparators", __FILE__)

class UnitTests::TestComparators::TestWithin < Test::Unit::TestCase
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
    field_1 = stub('field 1', :name => :foo, :ruby_type => { :type => Integer })
    field_2 = stub('field 2', :name => :bar, :ruby_type => { :type => Integer })
    assert_nothing_raised do
      Within.new(field_1, field_2, 123)
    end
  end

  test "score" do
    field_1 = stub('field 1', :name => :foo, :ruby_type => { :type => Integer })
    field_2 = stub('field 2', :name => :bar, :ruby_type => { :type => Integer })
    comp = Within.new(field_1, field_2, 123)
    assert_equal 1, comp.score({:foo => 123}, {:bar => 124})
    assert_equal 1, comp.score({:foo => 124}, {:bar => 123})
    assert_equal 1, comp.score({:foo => 0}, {:bar => 123})
    assert_equal 0, comp.score({:foo => 0}, {:bar => 124})
  end

  test "registers itself" do
    assert_equal Within, Linkage::Comparator['within']
  end

  test "requires that second argument has the same type as the first argument" do
    field_1 = stub('field 1', :name => :foo, :ruby_type => { :type => Integer })
    field_2 = stub('field 2', :name => :bar, :ruby_type => { :type => Date })
    assert_raises do
      Within.new(field_1, field_2, 123)
    end
  end
end
