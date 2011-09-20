require 'helper'

class UnitTests::TestExpectation < Test::Unit::TestCase
  test "new must expectation with two fields" do
    Linkage::MustExpectation.new(:==, stub('field 1'), stub('field 2'))
  end

  test "get" do
    assert_equal Linkage::MustExpectation, Linkage::Expectation.get(:must)
  end

  test "kind when two fields from different datasets" do
    dataset_1 = mock('dataset 1')
    dataset_2 = mock('dataset 2')
    field_1 = mock('field 1', :dataset => dataset_1)
    field_2 = mock('field 2', :dataset => dataset_2)
    field_1.expects(:==).with(field_2).returns(false)
    dataset_1.expects(:==).with(dataset_2).returns(false)
    exp = Linkage::MustExpectation.new(:==, field_1, field_2)
    assert_equal :dual, exp.kind
  end

  test "kind when two identical fields from the same dataset" do
    field_1 = mock('field 1')
    field_2 = mock('field 2')
    field_1.expects(:==).with(field_2).returns(true)
    exp = Linkage::MustExpectation.new(:==, field_1, field_2)
    assert_equal :self, exp.kind
  end

  test "kind when two different fields from the same dataset" do
    dataset_1 = mock('dataset 1')
    dataset_2 = mock('dataset 2')
    field_1 = mock('field 1', :dataset => dataset_1)
    field_2 = mock('field 2', :dataset => dataset_2)
    field_1.expects(:==).with(field_2).returns(false)
    dataset_1.expects(:==).with(dataset_2).returns(true)
    exp = Linkage::MustExpectation.new(:==, field_1, field_2)
    assert_equal :cross, exp.kind
  end

  test "apply a two-field dual expectation to two datasets" do
    dataset_1 = stub('dataset 1')
    dataset_2 = stub('dataset 2')
    field_1 = stub('field 1', :name => :foo, :dataset => dataset_1) do
      stubs(:belongs_to?).with(dataset_1, false).returns(true)
      stubs(:belongs_to?).with(dataset_2, false).returns(false)
    end
    field_2 = stub('field 2', :name => :foo, :dataset => dataset_2) do
      stubs(:belongs_to?).with(dataset_2, false).returns(true)
      stubs(:belongs_to?).with(dataset_1, false).returns(false)
    end
    merged_field = stub('merged field', :name => :foo)
    field_1.stubs(:merge).with(field_2).returns(merged_field)
    exp = Linkage::MustExpectation.new(:==, field_1, field_2)

    dataset_1.expects(:add_order).with(field_1)
    dataset_1.expects(:add_select).with(field_1, nil)
    exp.apply_to(dataset_1)

    dataset_2.expects(:add_order).with(field_2)
    dataset_2.expects(:add_select).with(field_2, nil)
    exp.apply_to(dataset_2)
  end

  test "apply a two-field dual expectation to two datasets with an alias" do
    dataset_1 = stub('dataset 1')
    dataset_2 = stub('dataset 2')
    field_1 = stub('field 1', :name => :foo, :dataset => dataset_1) do
      stubs(:belongs_to?).with(dataset_1, false).returns(true)
      stubs(:belongs_to?).with(dataset_2, false).returns(false)
    end
    field_2 = stub('field 2', :name => :bar, :dataset => dataset_2) do
      stubs(:belongs_to?).with(dataset_2, false).returns(true)
      stubs(:belongs_to?).with(dataset_1, false).returns(false)
    end
    merged_field = stub('merged field', :name => :foo_bar)
    field_1.stubs(:merge).with(field_2).returns(merged_field)
    exp = Linkage::MustExpectation.new(:==, field_1, field_2)

    dataset_1.expects(:add_order).with(field_1)
    dataset_1.expects(:add_select).with(field_1, :foo_bar)
    exp.apply_to(dataset_1)

    dataset_2.expects(:add_order).with(field_2)
    dataset_2.expects(:add_select).with(field_2, :foo_bar)
    exp.apply_to(dataset_2)
  end

  test "apply a two-field cross expectation" do
    dataset_1 = stub('dataset 1')
    dataset_2 = stub('dataset 2')
    dataset_1.stubs(:==).with(dataset_2).returns(true)
    field_1 = stub('field 1', :name => :foo, :dataset => dataset_1) do
      expects(:belongs_to?).with do |*args|
        args[0].equal?(dataset_1) && args[1].equal?(true)
      end.returns(true)
      expects(:belongs_to?).with do |*args|
        args[0].equal?(dataset_2) && args[1].equal?(true)
      end.returns(false)
    end
    field_2 = stub('field 2', :name => :bar, :dataset => dataset_1) do
      expects(:belongs_to?).with do |*args|
        args[0].equal?(dataset_2) && args[1].equal?(true)
      end.returns(true)
      expects(:belongs_to?).with do |*args|
        args[0].equal?(dataset_1) && args[1].equal?(true)
      end.returns(false)
    end
    merged_field = stub('merged field', :name => :foo_bar)
    field_1.stubs(:merge).with(field_2).returns(merged_field)
    exp = Linkage::MustExpectation.new(:==, field_1, field_2)

    dataset_1.expects(:add_order).with(field_1)
    dataset_1.expects(:add_select).with(field_1, :foo_bar)
    exp.apply_to(dataset_1)

    dataset_2.expects(:add_order).with(field_2)
    dataset_2.expects(:add_select).with(field_2, :foo_bar)
    exp.apply_to(dataset_2)
  end

  test "expectation name for join types" do
    field_1 = stub('field 1')
    field_2 = stub('field 2')
    merged_field = stub('merged field', :name => :foo_bar)
    field_1.stubs(:merge).with(field_2).returns(merged_field)

    exp = Linkage::MustExpectation.new(:==, field_1, field_2)
    assert_equal :foo_bar, exp.name
  end
end
