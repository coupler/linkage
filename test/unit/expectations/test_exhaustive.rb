require 'helper'

class UnitTests::TestExhaustive < Test::Unit::TestCase
  test "initialize with comparator, threshold, and mode" do
    comparator = stub('comparator')
    exp = Linkage::Expectations::Exhaustive.new(comparator, 100, :min)
    assert_equal comparator, exp.comparator
    assert_equal 100, exp.threshold
    assert_equal :min, exp.mode
  end

  test "kind" do
    comparator = stub('comparator')
    exp = Linkage::Expectations::Exhaustive.new(comparator, 100, :min)
    assert_equal :exhaustive, exp.kind
  end

  test "apply_to lhs dataset" do
    dataset = stub('dataset')
    new_dataset = stub('new dataset')
    meta_object_1 = stub('meta object 1', :name => :foo, :to_expr => :foo)
    meta_object_2 = stub('meta object 2', :name => :bar, :to_expr => :bar)
    comparator = stub('comparator', :lhs_args => [meta_object_1], :rhs_args => [meta_object_2])
    exp = Linkage::Expectations::Exhaustive.new(comparator, 100, :min)
    dataset.expects(:select_more).with(:foo.as(:foo)).returns(new_dataset)
    assert_equal new_dataset, exp.apply_to(dataset, :lhs)
  end

  test "apply_to rhs dataset" do
    dataset = stub('dataset')
    new_dataset = stub('new dataset')
    meta_object_1 = stub('meta object 1', :name => :foo, :to_expr => :foo)
    meta_object_2 = stub('meta object 2', :name => :bar, :to_expr => :bar)
    comparator = stub('comparator', :lhs_args => [meta_object_1], :rhs_args => [meta_object_2])
    exp = Linkage::Expectations::Exhaustive.new(comparator, 100, :min)
    dataset.expects(:select_more).with(:bar.as(:bar)).returns(new_dataset)
    assert_equal new_dataset, exp.apply_to(dataset, :rhs)
  end
end
