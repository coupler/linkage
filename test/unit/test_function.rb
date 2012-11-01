require 'helper'

class UnitTests::TestFunction < Test::Unit::TestCase

  def setup
    super
    @_functions = Linkage::Function.instance_variable_get("@functions")
  end

  def teardown
    Linkage::Function.instance_variable_set("@functions", @_functions)
    super
  end

  test "subclass of data" do
    assert_equal Linkage::Data, Linkage::Function.superclass
  end

  test "function_name returns nil in base class" do
    assert_raises(NotImplementedError) { Linkage::Function.function_name }
  end

  test "ruby_type raises not implemented error in base class" do
    klass = Class.new(Linkage::Function)
    klass.send(:define_singleton_method, :function_name) { "foo" }
    dataset = stub('dataset')
    f = klass.new(:dataset => dataset)
    assert_raises(NotImplementedError) { f.ruby_type }
  end

  test "registering subclass requires non-nil function_name" do
    klass = Class.new(Linkage::Function)
    assert_raises(ArgumentError) { Linkage::Function.register(klass) }
  end

  test "registering subclass requires ruby_type" do
    klass = new_function('foo')
    assert_raises(ArgumentError) { Linkage::Function.register(klass) }
  end

  test "function with no arguments" do
    klass = new_function('foo', {:type => String})
    f = klass.new(:dataset => stub('dataset'))
    assert_equal :foo, f.name
    assert_equal :foo.sql_function, f.to_expr
    assert f.static?
  end

  test "function with static value" do
    klass = new_function('foo', {:type => String})
    f = klass.new(123, :dataset => stub('dataset'))
    assert_equal :foo.sql_function(123), f.to_expr
    assert_equal :foo_123, f.name
    assert f.static?
  end

  test "function with field" do
    klass = new_function('foo', {:type => String})

    dataset = stub('dataset')
    field = stub_field('field', {
      :name => :bar, :to_expr => :bar,
      :ruby_type => {:type => String}, :dataset => dataset
    })
    f = klass.new(field)
    assert_equal :foo_bar, f.name
    assert_equal :foo.sql_function(:bar), f.to_expr
    assert_equal dataset, f.dataset
    assert !f.static?
  end

  test "creating function with conflicting datasets raises exception" do
    klass = new_function('foo', {:type => String}, [[String], [String]])

    dataset_1 = stub('dataset')
    field_1 = stub_field('field 1', {
      :name => :foo, :to_expr => :foo,
      :ruby_type => {:type => String}, :dataset => dataset_1
    })
    dataset_2 = stub('dataset')
    field_2 = stub_field('field 2', {
      :name => :bar, :to_expr => :bar,
      :ruby_type => {:type => String}, :dataset => dataset_2
    })

    assert_raises(ArgumentError) { klass.new(field_1, field_2) }
  end

  test "getting dataset for a static function without dataset raises exception" do
    klass = new_function('foo', {:type => String})
    func = klass.new
    assert_raises(RuntimeError) { func.dataset }
  end

  test "function with dynamic function" do
    klass_1 = new_function('foo', {:type => String})
    klass_2 = new_function('bar', {:type => String})

    field = stub_field('field', :name => :baz, :to_expr => :baz, :ruby_type => {:type => String}, :dataset => stub('dataset'))
    func_1 = klass_1.new(field)
    assert_equal :foo_baz, func_1.name
    assert !func_1.static?

    func_2 = klass_2.new(func_1)
    assert_equal :bar_foo_baz, func_2.name
    assert !func_2.static?
    assert_equal :bar.sql_function(:foo.sql_function(:baz)), func_2.to_expr
  end

  test "function with static function" do
    klass_1 = new_function('foo', {:type => String})
    klass_2 = new_function('bar', {:type => String})

    func_1 = klass_1.new(123, :dataset => stub('dataset'))
    assert_equal :foo_123, func_1.name
    assert func_1.static?

    func_2 = klass_2.new(func_1)
    assert_equal :bar_foo_123, func_2.name
    assert_equal :bar.sql_function(:foo.sql_function(123)), func_2.to_expr
    assert func_2.static?
  end

  test "function with mixed function arguments" do
    klass_1 = new_function('foo', {:type => String})
    klass_2 = new_function('bar', {:type => String})
    klass_3 = new_function('baz', {:type => String})

    dataset = stub('dataset')
    func_1 = klass_1.new(123, :dataset => dataset)
    assert_equal :foo_123, func_1.name
    assert func_1.static?

    field = stub_field('field', :name => :quux, :to_expr => :quux, :ruby_type => {:type => String}, :dataset => dataset)
    func_2 = klass_2.new(field)
    assert_equal :bar_quux, func_2.name
    assert !func_2.static?

    func_3 = klass_3.new(func_2, func_1)
    assert_equal :baz_bar_quux_foo_123, func_3.name
    assert !func_3.static?
    assert_equal :baz.sql_function(:bar.sql_function(:quux), :foo.sql_function(123)), func_3.to_expr
  end

  test "function with multiple fields" do
    klass = new_function('foo', {:type => String})
    dataset = stub('dataset')
    field_1 = stub_field('field', :name => :bar, :to_expr => :bar, :ruby_type => {:type => String}, :dataset => dataset)
    field_2 = stub_field('field', :name => :baz, :to_expr => :baz, :ruby_type => {:type => String}, :dataset => dataset)
    func = klass.new(field_1, field_2)
    assert_equal :foo_bar_baz, func.name
    assert_equal :foo.sql_function(:bar, :baz), func.to_expr
    assert !func.static?
  end

  test "function with multiple mixed arguments" do
    klass = new_function('foo', {:type => String})
    field = stub_field('field', :name => :bar, :to_expr => :bar, :ruby_type => {:type => String}, :dataset => stub('dataset'))
    f = klass.new(field, 123, 'abc')
    assert_equal :foo_bar_123_abc, f.name
    assert_equal :foo.sql_function(:bar, 123, 'abc'), f.to_expr
  end

  test "fetching registered function" do
    klass = new_function('foo', {:type => String})
    Linkage::Function.register(klass)
    assert_equal klass, Linkage::Function['foo']
  end

  test "valid parameters" do
    klass = new_function('foo', {:type => String}, [[String]])
    dataset = stub('dataset')
    assert_equal :foo.sql_function("foo"), klass.new("foo", :dataset => dataset).to_expr
    field = stub_field('field', :name => :bar, :to_expr => :bar, :ruby_type => {:type => String})
    assert_equal :foo.sql_function(:bar), klass.new(field, :dataset => dataset).to_expr
    assert_equal :foo.sql_function(:foo.sql_function("hey")), klass.new(klass.new("hey", :dataset => dataset)).to_expr
  end

  test "invalid parameters" do
    func = new_function('foo', {:type => String}, [[String]])
    assert_raises(TypeError) do
      func.new(123)
    end
    field = stub_field('field', :name => :bar, :to_expr => :bar, :ruby_type => {:type => Integer})
    assert_raises(TypeError) do
      func.new(field)
    end
    func2 = new_function('bar', {:type => Integer})
    dataset = stub('dataset')
    assert_raises(TypeError) do
      func.new(func2.new(:dataset => dataset))
    end
    assert_raises(ArgumentError) do
      func.new("123", "456")
    end
    assert_raises(ArgumentError) do
      func.new
    end
  end

  test "two functions with the same name and arguments and datasets are equal" do
    klass = new_function('foo', {:type => String}, [[String]])
    dataset = stub('dataset')
    field = stub_field('field', :dataset => dataset, :ruby_type => {:type => String})

    func_1 = klass.new(field)
    func_2 = klass.new(field)
    assert func_1 == func_2
  end

  test "#== with two static functions" do
    klass = new_function('foo', {:type => String}, [[String]])
    dataset = stub('dataset')
    func_1 = klass.new('foo', :dataset => dataset)
    func_2 = klass.new('foo', :dataset => dataset)
    assert func_1 == func_2
  end

  test "collation returns nil by default" do
    klass = new_function('foo', {:type => String}, [[String]])
    dataset = stub('dataset')
    func = klass.new('foo', :dataset => dataset)
    assert_nil func.collation
  end
end
