require 'helper'

class UnitTests::TestExpectation < Test::Unit::TestCase
  test "initialize with invalid operator" do
    assert_raises(ArgumentError) do
      Linkage::Expectation.new(stub(), stub(), :foo)
    end
  end

  test "creating filter expectation from a dynamic object and a static object" do
    field = stub('meta field', :static? => false, :side => :lhs)
    object = stub('meta object', :static? => true)
    exp = Linkage::Expectation.create(field, object, :==)
    assert_kind_of Linkage::FilterExpectation, exp
    assert_equal :lhs, exp.side
  end

  test "creating expectation from two static objects raises error" do
    object_1 = stub('meta object 1', :static? => true)
    object_2 = stub('meta object 2', :static? => true)
    assert_raises(ArgumentError) do
      Linkage::Expectation.create(object_1, object_2, :==)
    end
  end

  test "creating filter expectation from two dynamic objects with the same side" do
    field_1 = stub('meta field 1', :static? => false, :side => :lhs)
    field_2 = stub('meta field 2', :static? => false, :side => :lhs)
    field_1.expects(:datasets_equal?).with(field_2).returns(true)
    exp = Linkage::Expectation.create(field_1, field_2, :==)
    assert_kind_of Linkage::FilterExpectation, exp
    assert_equal :lhs, exp.side
  end

  test "creating filter expectation from two dynamic objects with the same side but different datasets raises error" do
    field_1 = stub('meta field 1', :static? => false, :side => :lhs)
    field_2 = stub('meta field 2', :static? => false, :side => :lhs)
    field_1.expects(:datasets_equal?).with(field_2).returns(false)
    assert_raises(ArgumentError) do
      Linkage::Expectation.create(field_1, field_2, :==)
    end
  end

  test "creating self expectation from two dynamic objects with different sides" do
    object_1 = stub('meta object 1', :static? => false, :side => :lhs)
    object_2 = stub('meta object 2', :static? => false, :side => :rhs)
    object_1.expects(:objects_equal?).with(object_2).returns(true)
    exp = Linkage::Expectation.create(object_1, object_2, :==)
    assert_kind_of Linkage::SelfExpectation, exp
  end

  test "creating cross expectation from two dynamic objects with different sides but same dataset" do
    object_1 = stub('meta object 1', :static? => false, :side => :lhs)
    object_2 = stub('meta object 2', :static? => false, :side => :rhs)
    object_1.expects(:objects_equal?).with(object_2).returns(false)
    object_1.expects(:datasets_equal?).with(object_2).returns(true)
    exp = Linkage::Expectation.create(object_1, object_2, :==)
    assert_kind_of Linkage::CrossExpectation, exp
  end

  test "creating dual expectation from two dynamic objects with different sides and datasets" do
    object_1 = stub('meta object 1', :static? => false, :side => :lhs)
    object_2 = stub('meta object 2', :static? => false, :side => :rhs)
    object_1.expects(:objects_equal?).with(object_2).returns(false)
    object_1.expects(:datasets_equal?).with(object_2).returns(false)
    exp = Linkage::Expectation.create(object_1, object_2, :==)
    assert_kind_of Linkage::DualExpectation, exp
  end

  test "apply_to with filter expectation (== operator)" do
    dataset = stub('dataset')
    meta_field_1 = stub('meta field 1', :static? => false, :side => :lhs)
    meta_field_2 = stub('meta field 2', :static? => false, :side => :lhs)
    meta_field_1.stubs(:datasets_equal?).with(meta_field_2).returns(true)

    exp = Linkage::Expectation.create(meta_field_1, meta_field_2, :==)
    meta_field_1.expects(:to_expr).returns(:foo)
    meta_field_2.expects(:to_expr).returns(:bar)
    dataset.expects(:filter).with({:foo => :bar}).returns(dataset)
    assert_equal dataset, exp.apply_to(dataset, :lhs)

    dataset.expects(:filter).never
    assert_equal dataset, exp.apply_to(dataset, :rhs)
  end

  test "apply_to with filter expectation (!= operator)" do
    dataset = stub('dataset')
    meta_field_1 = stub('meta field 1', :static? => false, :side => :lhs)
    meta_field_2 = stub('meta field 2', :static? => false, :side => :lhs)
    meta_field_1.stubs(:datasets_equal?).with(meta_field_2).returns(true)

    exp = Linkage::Expectation.create(meta_field_1, meta_field_2, :'!=')
    meta_field_1.expects(:to_expr).returns(:foo)
    meta_field_2.expects(:to_expr).returns(:bar)
    dataset.expects(:filter).with(~{:foo => :bar}).returns(dataset)
    assert_equal dataset, exp.apply_to(dataset, :lhs)

    dataset.expects(:filter).never
    assert_equal dataset, exp.apply_to(dataset, :rhs)
  end

  test "apply_to with filter expectation (> operator)" do
    dataset = stub('dataset')
    meta_field_1 = stub('meta field 1', :static? => false, :side => :lhs)
    meta_field_2 = stub('meta field 2', :static? => false, :side => :lhs)
    meta_field_1.stubs(:datasets_equal?).with(meta_field_2).returns(true)
    exp = Linkage::Expectation.create(meta_field_1, meta_field_2, :>)

    identifier_1 = Sequel::SQL::Identifier.new(:foo)
    meta_field_1.expects(:to_identifier).returns(identifier_1)
    identifier_2 = Sequel::SQL::Identifier.new(:bar)
    meta_field_2.expects(:to_identifier).returns(identifier_2)
    expected = Sequel::SQL::BooleanExpression.new(:>, identifier_1, identifier_2)

    dataset.expects(:filter).with(expected).returns(dataset)
    assert_equal dataset, exp.apply_to(dataset, :lhs)

    dataset.expects(:filter).never
    assert_equal dataset, exp.apply_to(dataset, :rhs)
  end

  test "apply_to with self expectation" do
    dataset = stub('dataset')
    object_1 = stub('meta object 1', {
      :static? => false, :side => :lhs, :dataset => dataset,
      :to_expr => :foo
    })
    object_2 = stub('meta object 2', {
      :static? => false, :side => :rhs, :dataset => dataset,
      :to_expr => :foo
    })
    object_1.expects(:objects_equal?).with(object_2).returns(true)
    exp = Linkage::Expectation.create(object_1, object_2, :==)

    merged_field = stub('merged field', :name => :foo)
    object_1.expects(:merge).with(object_2).returns(merged_field)
    dataset.expects(:match).with(object_1, :foo).returns(dataset)
    assert_equal dataset, exp.apply_to(dataset, :lhs)

    dataset.expects(:match).with(object_2, :foo).returns(dataset)
    assert_equal dataset, exp.apply_to(dataset, :rhs)
  end

  test "apply_to with cross expectation" do
    dataset = stub('dataset')
    object_1 = stub('meta object 1', {
      :static? => false, :side => :lhs, :dataset => dataset,
      :to_expr => :foo
    })
    object_2 = stub('meta object 2', {
      :static? => false, :side => :rhs, :dataset => dataset,
      :to_expr => :bar
    })
    object_1.stubs(:objects_equal?).with(object_2).returns(false)
    object_1.stubs(:datasets_equal?).with(object_2).returns(true)
    exp = Linkage::Expectation.create(object_1, object_2, :==)

    merged_field = stub('merged field', :name => :foo_bar)
    object_1.expects(:merge).with(object_2).returns(merged_field)
    dataset.expects(:match).with(object_1, :foo_bar).returns(dataset)
    assert_equal dataset, exp.apply_to(dataset, :lhs)

    dataset.expects(:match).with(object_2, :foo_bar).returns(dataset)
    assert_equal dataset, exp.apply_to(dataset, :rhs)
  end

  test "apply_to with dual expectation" do
    dataset_1 = stub('dataset 1')
    object_1 = stub('meta object 1', {
      :static? => false, :side => :lhs, :dataset => dataset_1,
      :to_expr => :foo
    })
    dataset_2 = stub('dataset 2')
    object_2 = stub('meta object 2', {
      :static? => false, :side => :rhs, :dataset => dataset_2,
      :to_expr => :foo
    })
    object_1.stubs(:objects_equal?).with(object_2).returns(false)
    object_1.stubs(:datasets_equal?).with(object_2).returns(false)
    exp = Linkage::Expectation.create(object_1, object_2, :==)

    merged_field = stub('merged field', :name => :foo)
    object_1.expects(:merge).with(object_2).returns(merged_field)
    dataset_1.expects(:match).with(object_1, :foo).returns(dataset_1)
    assert_equal dataset_1, exp.apply_to(dataset_1, :lhs)

    dataset_2.expects(:match).with(object_2, :foo).returns(dataset_2)
    assert_equal dataset_2, exp.apply_to(dataset_2, :rhs)
  end

  test "exactly! wraps each side inside the binary function" do
    dataset_1 = stub('dataset 1')
    field_1 = stub_field('field 1', :dataset => dataset_1)
    meta_object_1 = stub('meta object 1', :static? => false, :side => :lhs,
                         :object => field_1, :dataset => dataset_1)

    dataset_2 = stub('dataset 2')
    field_2 = stub_field('field 2', :dataset => dataset_2)
    meta_object_2 = stub('meta object 2', :static? => false, :side => :rhs,
                         :object => field_2, :dataset => dataset_2)
    meta_object_1.stubs(:objects_equal?).with(meta_object_2).returns(true)

    exp = Linkage::Expectation.create(meta_object_1, meta_object_2, :==)

    klass = Linkage::Functions::Binary
    func_1 = stub('binary function 1')
    klass.expects(:new).with(field_1, :dataset => dataset_1).returns(func_1)
    func_2 = stub('binary function 2')
    klass.expects(:new).with(field_2, :dataset => dataset_2).returns(func_2)

    new_meta_object_1 = stub('new meta object 1')
    Linkage::MetaObject.expects(:new).with(func_1, :lhs).returns(new_meta_object_1)
    new_meta_object_2 = stub('new meta object 2')
    Linkage::MetaObject.expects(:new).with(func_2, :rhs).returns(new_meta_object_2)

    exp.exactly!
    # LAZY: assume the expectation set its meta objects appropriately
  end

  test "#same_except_side with two filter expectations" do
    field = stub_field('foo')
    meta_object_1 = stub('meta field 1', {
      :static? => false, :side => :lhs, :object => field
    })
    meta_object_2 = stub('meta object', :static? => true)
    meta_object_3 = stub('meta field 2', {
      :static? => false, :side => :rhs, :object => field
    })

    exp_1 = Linkage::Expectation.create(meta_object_1, meta_object_2, :==)
    exp_2 = Linkage::Expectation.create(meta_object_3, meta_object_2, :==)

    meta_object_1.expects(:objects_equal?).with(meta_object_3).returns(true)
    meta_object_2.expects(:objects_equal?).with(meta_object_2).returns(true)
    assert exp_1.same_except_side?(exp_2)
  end

  test "#decollation_needed? is false when comparing non-string objects" do
    dataset_1 = stub('dataset 1')
    object_1 = stub('meta object 1', {
      :static? => false, :side => :lhs, :dataset => dataset_1,
    })
    dataset_2 = stub('dataset 2')
    object_2 = stub('meta object 2', {
      :static? => false, :side => :rhs, :dataset => dataset_2,
    })
    merged_field = stub('merged field', :ruby_type => {:type => Fixnum})
    object_1.stubs(:merge).with(object_2).returns(merged_field)
    exp = Linkage::DualExpectation.new(object_1, object_2, :==)
    assert !exp.decollation_needed?
  end

  test "#decollation_needed? is false when comparing two dynamic string objects with the same database type and same collation" do
    dataset_1 = stub('dataset 1')
    object_1 = stub('meta object 1', {
      :static? => false, :side => :lhs, :dataset => dataset_1,
      :collation => 'foo', :database_type => :mysql
    })
    dataset_2 = stub('dataset 2')
    object_2 = stub('meta object 2', {
      :static? => false, :side => :rhs, :dataset => dataset_2,
      :collation => 'foo', :database_type => :mysql
    })
    merged_field = stub('merged field', :ruby_type => {:type => String})
    object_1.stubs(:merge).with(object_2).returns(merged_field)
    exp = Linkage::DualExpectation.new(object_1, object_2, :==)
    assert !exp.decollation_needed?
  end

  test "#decollation_needed? is true when comparing two dynamic string objects with the same database type but different collations" do
    dataset_1 = stub('dataset 1')
    object_1 = stub('meta object 1', {
      :static? => false, :side => :lhs, :dataset => dataset_1,
      :collation => 'foo', :database_type => :mysql
    })
    dataset_2 = stub('dataset 2')
    object_2 = stub('meta object 2', {
      :static? => false, :side => :rhs, :dataset => dataset_2,
      :collation => 'bar', :database_type => :mysql
    })
    merged_field = stub('merged field', :ruby_type => {:type => String})
    object_1.stubs(:merge).with(object_2).returns(merged_field)
    exp = Linkage::DualExpectation.new(object_1, object_2, :==)
    assert exp.decollation_needed?
  end

  test "#decollation_needed? is true when comparing two dynamic string objects with same collation but different database types" do
    dataset_1 = stub('dataset 1')
    object_1 = stub('meta object 1', {
      :static? => false, :side => :lhs, :dataset => dataset_1,
      :collation => 'foo', :database_type => :foo
    })
    dataset_2 = stub('dataset 2')
    object_2 = stub('meta object 2', {
      :static? => false, :side => :rhs, :dataset => dataset_2,
      :collation => 'foo', :database_type => :bar
    })
    merged_field = stub('merged field', :ruby_type => {:type => String})
    object_1.stubs(:merge).with(object_2).returns(merged_field)
    exp = Linkage::DualExpectation.new(object_1, object_2, :==)
    assert exp.decollation_needed?
  end
end
