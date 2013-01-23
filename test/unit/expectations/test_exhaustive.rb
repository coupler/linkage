require 'helper'

class UnitTests::TestExhaustive < Test::Unit::TestCase
  test "initialize with comparator, threshold, and mode" do
    comparator = stub('comparator')
    exp = Linkage::Expectations::Exhaustive.new(comparator, 100, :min)
    assert_equal comparator, exp.comparator
    assert_equal 100, exp.threshold
    assert_equal :min, exp.mode
  end

  test "kind is :self when comparator has same args on both sides" do
    meta_object_1 = stub('meta object 1')
    meta_object_2 = stub('meta object 2')
    meta_object_1.expects(:objects_equal?).with(meta_object_2).returns(true)
    comparator = stub('comparator', {
      :lhs_args => [meta_object_1], :rhs_args => [meta_object_2]
    })
    exp = Linkage::Expectations::Exhaustive.new(comparator, 100, :min)
    assert_equal :self, exp.kind
  end

  test "kind is :cross when comparator has args with same dataset but different number of args" do
    meta_object_1 = stub('meta object 1')
    meta_object_2 = stub('meta object 2')
    meta_object_3 = stub('meta object 3')
    meta_object_1.expects(:datasets_equal?).with(meta_object_2).returns(true)
    comparator = stub('comparator', {
      :lhs_args => [meta_object_1], :rhs_args => [meta_object_2, meta_object_3]
    })
    exp = Linkage::Expectations::Exhaustive.new(comparator, 100, :min)
    assert_equal :cross, exp.kind
  end

  test "kind is :cross when comparator has args with same dataset but different objects" do
    meta_object_1 = stub('meta object 1')
    meta_object_2 = stub('meta object 2')
    meta_object_1.expects(:objects_equal?).with(meta_object_2).returns(false)
    meta_object_1.expects(:datasets_equal?).with(meta_object_2).returns(true)
    comparator = stub('comparator', {
      :lhs_args => [meta_object_1], :rhs_args => [meta_object_2]
    })
    exp = Linkage::Expectations::Exhaustive.new(comparator, 100, :min)
    assert_equal :cross, exp.kind
  end

  test "kind is :dual when comparator has args with different datasets and different number of args" do
    meta_object_1 = stub('meta object 1')
    meta_object_2 = stub('meta object 2')
    meta_object_3 = stub('meta object 3')
    meta_object_1.expects(:datasets_equal?).with(meta_object_2).returns(false)
    comparator = stub('comparator', {
      :lhs_args => [meta_object_1], :rhs_args => [meta_object_2, meta_object_3]
    })
    exp = Linkage::Expectations::Exhaustive.new(comparator, 100, :min)
    assert_equal :dual, exp.kind
  end

  test "kind is :dual when comparator has args with different datasets" do
    meta_object_1 = stub('meta object 1')
    meta_object_2 = stub('meta object 2')
    meta_object_1.expects(:objects_equal?).with(meta_object_2).returns(false)
    meta_object_1.expects(:datasets_equal?).with(meta_object_2).returns(false)
    comparator = stub('comparator', {
      :lhs_args => [meta_object_1], :rhs_args => [meta_object_2]
    })
    exp = Linkage::Expectations::Exhaustive.new(comparator, 100, :min)
    assert_equal :dual, exp.kind
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

  test "satisfied? with :equal mode" do
    meta_object_1 = stub('meta object 1')
    meta_object_2 = stub('meta object 2')
    comparator = stub('comparator', :lhs_args => [meta_object_1], :rhs_args => [meta_object_2])
    exp = Linkage::Expectations::Exhaustive.new(comparator, 50, :equal)
    assert exp.satisfied?(50)
    assert !exp.satisfied?(123)
  end

  test "satisfied? with :min mode" do
    meta_object_1 = stub('meta object 1')
    meta_object_2 = stub('meta object 2')
    comparator = stub('comparator', :lhs_args => [meta_object_1], :rhs_args => [meta_object_2])
    exp = Linkage::Expectations::Exhaustive.new(comparator, 50, :min)
    assert exp.satisfied?(50)
    assert exp.satisfied?(55)
    assert !exp.satisfied?(45)
  end
end
