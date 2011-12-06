require 'helper'

class UnitTests::TestExpectation < Test::Unit::TestCase
  test "new must expectation with two fields" do
    Linkage::MustExpectation.new(:==, stub_field('field 1'), stub_field('field 2'))
  end

  test "get" do
    assert_equal Linkage::MustExpectation, Linkage::Expectation.get(:must)
  end

  test "kind when two fields from different datasets" do
    dataset_1 = mock('dataset 1')
    dataset_2 = mock('dataset 2')
    field_1 = stub_field('field 1', :dataset => dataset_1)
    field_2 = stub_field('field 2', :dataset => dataset_2)
    field_1.expects(:==).with(field_2).returns(false)
    dataset_1.expects(:==).with(dataset_2).returns(false)
    exp = Linkage::MustExpectation.new(:==, field_1, field_2)
    assert_equal :dual, exp.kind
  end

  test "kind when one field and one function from different datasets" do
    dataset_1 = mock('dataset 1')
    dataset_2 = mock('dataset 2')
    field = stub_field('field', :dataset => dataset_1)
    func = stub_function('function', :dataset => dataset_2, :static? => false)
    field.expects(:==).with(func).returns(false)
    dataset_1.expects(:==).with(dataset_2).returns(false)
    exp = Linkage::MustExpectation.new(:==, field, func)
    assert_equal :dual, exp.kind
  end

  test "kind when two functions from different datasets" do
    dataset_1 = mock('dataset 1')
    dataset_2 = mock('dataset 2')
    func_1 = stub_function('function 1', :dataset => dataset_1, :static? => false)
    func_2 = stub_function('function 2', :dataset => dataset_2, :static? => false)
    func_1.expects(:==).with(func_2).returns(false)
    dataset_1.expects(:==).with(dataset_2).returns(false)
    exp = Linkage::MustExpectation.new(:==, func_1, func_2)
    assert_equal :dual, exp.kind
  end

  test "kind when two identical fields from the same dataset" do
    field_1 = stub_field('field 1')
    field_2 = stub_field('field 2')
    field_1.expects(:==).with(field_2).returns(true)
    exp = Linkage::MustExpectation.new(:==, field_1, field_2)
    assert_equal :self, exp.kind
  end

  test "kind when two identical functions from the same dataset" do
    func_1 = stub_function('function 1')
    func_2 = stub_function('function 2')
    func_1.expects(:==).with(func_2).returns(true)
    exp = Linkage::MustExpectation.new(:==, func_1, func_2)
    assert_equal :self, exp.kind
  end

  test "kind when two different fields from the same dataset" do
    dataset_1 = mock('dataset 1')
    dataset_2 = mock('dataset 2')
    field_1 = stub_field('field 1', :dataset => dataset_1)
    field_2 = stub_field('field 2', :dataset => dataset_2)
    field_1.expects(:==).with(field_2).returns(false)
    dataset_1.expects(:==).with(dataset_2).returns(true)
    exp = Linkage::MustExpectation.new(:==, field_1, field_2)
    assert_equal :cross, exp.kind
  end

  test "kind when two different functions from the same dataset" do
    dataset_1 = mock('dataset 1')
    dataset_2 = mock('dataset 2')
    func_1 = stub_function('function 1', :dataset => dataset_1)
    func_2 = stub_function('function 2', :dataset => dataset_2)
    func_1.expects(:==).with(func_2).returns(false)
    dataset_1.expects(:==).with(dataset_2).returns(true)
    exp = Linkage::MustExpectation.new(:==, func_1, func_2)
    assert_equal :cross, exp.kind
  end

  test "manually set kind with two different fields from the same dataset" do
    dataset = mock('dataset 1')
    field_1 = stub_field('field 1', :dataset => dataset)
    field_2 = stub_field('field 2', :dataset => dataset)
    exp = Linkage::MustExpectation.new(:==, field_1, field_2, :filter)
    assert_equal :filter, exp.kind
  end

  test "apply a two-field dual expectation to two datasets" do
    dataset_1 = stub('dataset 1')
    dataset_2 = stub('dataset 2')
    field_1 = stub_field('field 1', :name => :foo, :dataset => dataset_1) do
      stubs(:belongs_to?).with(dataset_1).returns(true)
      stubs(:belongs_to?).with(dataset_2).returns(false)
    end
    field_2 = stub_field('field 2', :name => :foo, :dataset => dataset_2) do
      stubs(:belongs_to?).with(dataset_2).returns(true)
      stubs(:belongs_to?).with(dataset_1).returns(false)
    end
    merged_field = stub_field('merged field', :name => :foo)
    field_1.stubs(:merge).with(field_2).returns(merged_field)
    exp = Linkage::MustExpectation.new(:==, field_1, field_2)

    dataset_1.expects(:add_order).with(field_1)
    dataset_1.expects(:add_select).with(field_1, nil)
    exp.apply_to(dataset_1)

    dataset_2.expects(:add_order).with(field_2)
    dataset_2.expects(:add_select).with(field_2, nil)
    exp.apply_to(dataset_2)
  end

  test "apply a two-function dual expectation to two datasets" do
    dataset_1 = stub('dataset 1')
    dataset_2 = stub('dataset 2')
    func_1 = stub_function('function 1', :name => :foo, :dataset => dataset_1) do
      stubs(:belongs_to?).with(dataset_1).returns(true)
      stubs(:belongs_to?).with(dataset_2).returns(false)
    end
    func_2 = stub_function('function 2', :name => :bar, :dataset => dataset_2) do
      stubs(:belongs_to?).with(dataset_2).returns(true)
      stubs(:belongs_to?).with(dataset_1).returns(false)
    end
    merged_field = stub_field('merged field', :name => :foo_bar)
    func_1.stubs(:merge).with(func_2).returns(merged_field)
    exp = Linkage::MustExpectation.new(:==, func_1, func_2)

    dataset_1.expects(:add_order).with(func_1)
    dataset_1.expects(:add_select).with(func_1, :foo_bar)
    exp.apply_to(dataset_1)

    dataset_2.expects(:add_order).with(func_2)
    dataset_2.expects(:add_select).with(func_2, :foo_bar)
    exp.apply_to(dataset_2)
  end

  test "apply a two-field dual expectation to two datasets with an alias" do
    dataset_1 = stub('dataset 1')
    dataset_2 = stub('dataset 2')
    field_1 = stub_field('field 1', :name => :foo, :dataset => dataset_1) do
      stubs(:belongs_to?).with(dataset_1).returns(true)
      stubs(:belongs_to?).with(dataset_2).returns(false)
    end
    field_2 = stub_field('field 2', :name => :bar, :dataset => dataset_2) do
      stubs(:belongs_to?).with(dataset_2).returns(true)
      stubs(:belongs_to?).with(dataset_1).returns(false)
    end
    merged_field = stub_field('merged field', :name => :foo_bar)
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
    field_1 = stub_field('field 1', :name => :foo, :dataset => dataset_1) do
      expects(:belongs_to?).with do |*args|
        args[0].equal?(dataset_1)
      end.returns(true)
      expects(:belongs_to?).with do |*args|
        args[0].equal?(dataset_2)
      end.returns(false)
    end
    field_2 = stub_field('field 2', :name => :bar, :dataset => dataset_1) do
      expects(:belongs_to?).with do |*args|
        args[0].equal?(dataset_2)
      end.returns(true)
      expects(:belongs_to?).with do |*args|
        args[0].equal?(dataset_1)
      end.returns(false)
    end
    merged_field = stub_field('merged field', :name => :foo_bar)
    field_1.stubs(:merge).with(field_2).returns(merged_field)
    exp = Linkage::MustExpectation.new(:==, field_1, field_2)

    dataset_1.expects(:add_order).with(field_1)
    dataset_1.expects(:add_select).with(field_1, :foo_bar)
    exp.apply_to(dataset_1)

    dataset_2.expects(:add_order).with(field_2)
    dataset_2.expects(:add_select).with(field_2, :foo_bar)
    exp.apply_to(dataset_2)
  end

  test "apply a two-field self expectation" do
    dataset = stub('dataset')
    field = stub_field('field 1', :name => :foo, :dataset => dataset) do
      expects(:belongs_to?).with(dataset).twice.returns(true)
    end
    exp = Linkage::MustExpectation.new(:==, field, field)

    # Twice is okay, since add_order/add_select will take care of
    # duplicates.
    dataset.expects(:add_order).twice.with(field, nil)
    dataset.expects(:add_select).twice.with(field, nil)
    exp.apply_to(dataset)
  end

  test "apply a two-function self expectation" do
    dataset = stub('dataset')
    func = stub_function('function', :name => :foo, :dataset => dataset) do
      expects(:belongs_to?).with(dataset).twice.returns(true)
    end
    exp = Linkage::MustExpectation.new(:==, func, func)

    # Twice is okay, since add_order/add_select will take care of
    # duplicates.
    dataset.expects(:add_order).twice.with(func)
    dataset.expects(:add_select).twice.with(func, :foo)
    exp.apply_to(dataset)
  end

  test "apply a two-field self expectation like a cross" do
    dataset_1 = stub('dataset 1')
    dataset_2 = stub('dataset 2')
    field_1 = stub_field('field 1', :name => :foo, :dataset => dataset_1) do
      expects(:belongs_to?).with(dataset_1).returns(true)
      expects(:belongs_to?).with(dataset_2).returns(false)
    end
    field_2 = stub_field('field 2', :name => :foo, :dataset => dataset_2) do
      expects(:belongs_to?).with(dataset_2).returns(true)
      expects(:belongs_to?).with(dataset_1).returns(false)
    end
    exp = Linkage::MustExpectation.new(:==, field_1, field_2, :self)

    dataset_1.expects(:add_order).once.with(field_1, nil)
    dataset_1.expects(:add_select).once.with(field_1, nil)
    exp.apply_to(dataset_1)

    dataset_2.expects(:add_order).once.with(field_2, nil)
    dataset_2.expects(:add_select).once.with(field_2, nil)
    exp.apply_to(dataset_2)
  end

  test "expectation name for join types" do
    field_1 = stub_field('field 1')
    field_2 = stub_field('field 2')
    merged_field = stub_field('merged field', :name => :foo_bar)
    field_1.stubs(:merge).with(field_2).returns(merged_field)

    exp = Linkage::MustExpectation.new(:==, field_1, field_2)
    assert_equal :foo_bar, exp.name
  end

  test "expectation with static value is of type 'filter'" do
    field = stub_field('field')
    exp = Linkage::MustExpectation.new(:==, field, 123)
    assert_equal :filter, exp.kind
  end

  test "expectation with static function is of type 'filter'" do
    field = stub_field('field')
    func = stub_function('func', :static? => true)
    exp = Linkage::MustExpectation.new(:==, field, func)
    assert_equal :filter, exp.kind
  end

  test "apply filter expectation" do
    dataset_1 = stub('dataset 1')
    dataset_2 = stub('dataset 2')
    field = stub_field('field', :dataset => dataset_1)
    exp = Linkage::MustExpectation.new(:==, field, 123)

    dataset_1.expects(:add_filter).with(field, :==, 123)
    field.expects(:belongs_to?).with(dataset_1).returns(true)
    exp.apply_to(dataset_1)
    field.expects(:belongs_to?).with(dataset_2).returns(false)
    exp.apply_to(dataset_2)
  end

  test "apply filter expectation, static value first" do
    dataset_1 = stub('dataset 1')
    dataset_2 = stub('dataset 2')
    field = stub_field('field', :dataset => dataset_1)
    exp = Linkage::MustExpectation.new(:==, 123, field)

    dataset_1.expects(:add_filter).with(field, :==, 123)
    field.expects(:belongs_to?).with(dataset_1).returns(true)
    exp.apply_to(dataset_1)
    field.expects(:belongs_to?).with(dataset_2).returns(false)
    exp.apply_to(dataset_2)
  end

  test "apply two-field filter expectation" do
    dataset = stub('dataset')
    field_1 = stub_field('field 1', :dataset => dataset)
    field_2 = stub_field('field 2', :dataset => dataset)
    exp = Linkage::MustExpectation.new(:==, field_1, field_2, :filter)

    dataset.expects(:add_filter).with(field_1, :==, field_2)
    field_1.expects(:belongs_to?).with(dataset).returns(true)
    exp.apply_to(dataset)
  end

  test "creating expectation with two non-fields raises ArgumentError" do
    assert_raises(ArgumentError) do
      exp = Linkage::MustExpectation.new(:==, 123, 456)
    end
  end

  test "raise error if operator is not supported" do
    field = stub_field('field')
    assert_raises(ArgumentError) do
      exp = Linkage::MustExpectation.new(:foo, field, 456)
    end
  end

  [:>, :<, :>=, :<=, :'!='].each do |operator|
    test "#{operator} filter expectation" do
      dataset_1 = stub('dataset 1')
      dataset_2 = stub('dataset 2')
      field = stub_field('field', :dataset => dataset_1)
      exp = Linkage::MustExpectation.new(operator, field, 123)

      dataset_1.expects(:add_filter).with(field, operator, 123)
      field.expects(:belongs_to?).with(dataset_1).returns(true)
      exp.apply_to(dataset_1)
      field.expects(:belongs_to?).with(dataset_2).returns(false)
      exp.apply_to(dataset_2)
    end
  end

  test "only allows :== for non-filter expectations between two fields" do
    field_1 = stub_field('field 1')
    field_2 = stub_field('field 2')
    assert_raises(ArgumentError) do
      Linkage::MustExpectation.new(:>, field_1, field_2)
    end
  end

  test "applies_to? with filter expectation" do
    dataset = stub('dataset')
    field = stub_field('field')
    exp = Linkage::MustExpectation.new(:==, field, 123)
    assert_equal :filter, exp.kind

    field.expects(:belongs_to?).with(dataset).returns(true)
    assert exp.applies_to?(dataset)
  end

  test "applies_to? with non-filter expectation" do
    dataset_1 = stub('dataset 1')
    field_1 = stub_field('field 1')
    dataset_2 = stub('dataset 2')
    field_2 = stub_field('field 2')
    exp = Linkage::MustExpectation.new(:==, field_1, field_2)
    assert_not_equal :filter, exp.kind

    field_1.expects(:belongs_to?).with(dataset_1).returns(true)
    assert exp.applies_to?(dataset_1)

    field_1.expects(:belongs_to?).with(dataset_2).returns(false)
    field_2.expects(:belongs_to?).with(dataset_2).returns(true)
    assert exp.applies_to?(dataset_2)
  end

  test "MustNotExpectation negates operator" do
    dataset_1 = stub('dataset 1')
    dataset_2 = stub('dataset 2')
    field = stub_field('field', :dataset => dataset_1)
    exp = Linkage::MustNotExpectation.new(:==, field, 123)

    dataset_1.expects(:add_filter).with(field, :'!=', 123)
    field.expects(:belongs_to?).with(dataset_1).returns(true)
    exp.apply_to(dataset_1)
    field.expects(:belongs_to?).with(dataset_2).returns(false)
    exp.apply_to(dataset_2)
  end

  test "allows a dynamic function filter" do
    func = stub_function("foo", :static? => false)
    exp = Linkage::MustNotExpectation.new(:==, func, 123)
  end

  test "does not allow a static function filter" do
    func = stub_function("foo", :static? => true)
    assert_raises(ArgumentError) { Linkage::MustNotExpectation.new(:==, func, 123) }
  end
end
