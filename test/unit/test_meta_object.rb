require 'helper'

class UnitTests::TestMetaObject < Test::Unit::TestCase
  test "initialize with static string" do
    meta_object = Linkage::MetaObject.new("foo")
    assert meta_object.static?
    assert_equal "foo", meta_object.object
    assert_nil meta_object.side
  end

  test "initialize with static function" do
    function = stub_function("foo", :static? => true)
    meta_object = Linkage::MetaObject.new(function)
    assert meta_object.static?
    assert_equal function, meta_object.object
    assert_nil meta_object.side
  end

  test "initialize with field" do
    field = stub_field("foo")
    meta_object = Linkage::MetaObject.new(field, :lhs)
    assert !meta_object.static?
    assert_equal field, meta_object.object
    assert_equal :lhs, meta_object.side
  end

  test "getting side for dynamic object without setting it raises error" do
    meta_object = Linkage::MetaObject.new(stub_field('foo'))
    assert_raises(RuntimeError) { meta_object.side }
  end

  test "getting dataset calls #dataset on object" do
    field = stub_field('foo')
    meta_object = Linkage::MetaObject.new(field)

    dataset = stub('dataset')
    field.expects(:dataset).returns(dataset)
    assert_equal dataset, meta_object.dataset
  end

  test "setting dataset sets object's dataset" do
    func = stub_function('foo')
    meta_object = Linkage::MetaObject.new(func)

    dataset = stub('dataset')
    func.expects(:dataset=).with(dataset)
    meta_object.dataset = dataset
  end

  test "setting dataset on non-data object raises exception" do
    meta_object = Linkage::MetaObject.new(123)
    dataset = stub('dataset')
    assert_raises(RuntimeError) { meta_object.dataset = dataset }
  end

  test "objects_equal? compares only objects, not sides" do
    field = stub_field("foo")
    object_1 = Linkage::MetaObject.new(field, :lhs)
    object_2 = Linkage::MetaObject.new(field, :rhs)
    object_3 = Linkage::MetaObject.new(123)
    assert object_1.objects_equal?(object_2)
    assert !object_1.objects_equal?("foo")
    assert !object_2.objects_equal?(object_3)
  end

  test "dataset reader for field" do
    dataset = stub('dataset')
    field = stub_field("foo", :dataset => dataset)
    object = Linkage::MetaObject.new(field, :lhs)

    assert_equal dataset, object.dataset
  end

  test "dataset reader for function" do
    dataset = stub('dataset')
    function = stub_function("foo", :dataset => dataset)
    object = Linkage::MetaObject.new(function, :lhs)

    assert_equal dataset, object.dataset
  end

  test "datasets_equal?" do
    dataset_1 = stub('dataset 1')
    field_1 = stub_field('field 1', :dataset => dataset_1)
    object_1 = Linkage::MetaObject.new(field_1, :lhs)

    dataset_2 = stub('dataset 2')
    field_2 = stub_field('field 2', :dataset => dataset_2)
    object_2 = Linkage::MetaObject.new(field_2, :rhs)

    field_3 = stub_field('field 3', :dataset => dataset_2)
    object_3 = Linkage::MetaObject.new(field_3, :rhs)

    object_4 = Linkage::MetaObject.new(123)

    assert object_1.datasets_equal?(object_1)
    assert object_2.datasets_equal?(object_3)
    assert !object_1.datasets_equal?(object_2)
    assert !object_1.datasets_equal?("foo")
    assert !object_1.datasets_equal?(object_4)
  end

  test "to_expr for non-data object returns object" do
    object = Linkage::MetaObject.new(123)
    assert_equal 123, object.to_expr
  end

  test "to_expr for data object returns object.to_expr" do
    field = stub_field('field')
    object = Linkage::MetaObject.new(field, :lhs)

    field.expects(:to_expr).returns(:foo)
    assert_equal :foo, object.to_expr
  end

  test "to_identifier for non-data object returns object" do
    object = Linkage::MetaObject.new(123)
    assert_equal 123, object.to_identifier
  end

  test "to_identifer for data object returns identifier object" do
    field = stub_field('field')
    object = Linkage::MetaObject.new(field, :lhs)

    field.expects(:to_expr).returns(:foo)
    assert_equal(Sequel::SQL::Identifier.new(:foo), object.to_identifier)
  end

  test "merge with data object" do
    field_1 = stub_field('field 1')
    object_1 = Linkage::MetaObject.new(field_1, :lhs)
    field_2 = stub_field('field 2')
    object_2 = Linkage::MetaObject.new(field_2, :rhs)

    merged_field = stub('merged field')
    field_1.expects(:merge).with(field_2).returns(merged_field)
    assert_equal merged_field, object_1.merge(object_2)
  end

  test "merge with non-data object raises exception" do
    field_1 = stub_field('field 1')
    object_1 = Linkage::MetaObject.new(field_1, :lhs)
    object_2 = Linkage::MetaObject.new(123)
    assert_raises(ArgumentError) { object_1.merge(object_2) }
    assert_raises(ArgumentError) { object_2.merge(object_1) }
  end
end
