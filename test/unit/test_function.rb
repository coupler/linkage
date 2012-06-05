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
    f = klass.new
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
    f = klass.new
    assert_equal :foo, f.name
    assert_equal :foo.sql_function, f.to_expr
    assert f.static?
  end

  test "function with static value" do
    klass = new_function('foo', {:type => String})
    f = klass.new(123)
    assert_equal :foo.sql_function(123), f.to_expr
    assert_equal :foo_123, f.name
    assert f.static?
  end

  test "function with field" do
    klass = new_function('foo', {:type => String})
    field = stub_field('field', :name => :bar, :to_expr => :bar, :ruby_type => {:type => String})
    f = klass.new(field)
    assert_equal :foo_bar, f.name
    assert_equal :foo.sql_function(:bar), f.to_expr
    assert !f.static?
  end

  test "function with dynamic function" do
    klass_1 = new_function('foo', {:type => String})
    klass_2 = new_function('bar', {:type => String})

    field = stub_field('field', :name => :baz, :to_expr => :baz, :ruby_type => {:type => String})
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

    func_1 = klass_1.new(123)
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

    func_1 = klass_1.new(123)
    assert_equal :foo_123, func_1.name
    assert func_1.static?

    field = stub_field('field', :name => :quux, :to_expr => :quux, :ruby_type => {:type => String})
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
    field_1 = stub_field('field', :name => :bar, :to_expr => :bar, :ruby_type => {:type => String})
    field_2 = stub_field('field', :name => :baz, :to_expr => :baz, :ruby_type => {:type => String})
    func = klass.new(field_1, field_2)
    assert_equal :foo_bar_baz, func.name
    assert_equal :foo.sql_function(:bar, :baz), func.to_expr
    assert !func.static?
  end

  test "function with multiple mixed arguments" do
    klass = new_function('foo', {:type => String})
    field = stub_field('field', :name => :bar, :to_expr => :bar, :ruby_type => {:type => String})
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
    func = new_function('foo', {:type => String}, [[String]])
    assert_equal :foo.sql_function("foo"), func.new("foo").to_expr
    field = stub_field('field', :name => :bar, :to_expr => :bar, :ruby_type => {:type => String})
    assert_equal :foo.sql_function(:bar), func.new(field).to_expr
    assert_equal :foo.sql_function(:foo.sql_function("hey")), func.new(func.new("hey")).to_expr
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
    assert_raises(TypeError) do
      func.new(func2.new)
    end
    assert_raises(ArgumentError) do
      func.new("123", "456")
    end
    assert_raises(ArgumentError) do
      func.new
    end
  end

  test "to_expr with binary" do
    func = new_function('foo', {:type => String}, [[String]])
    assert_equal :foo.sql_function("foo").cast(:binary), func.new("foo").to_expr(nil, :binary => true)
  end
end
