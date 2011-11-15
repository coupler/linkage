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
    f = Linkage::Function.new
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
    assert_equal :foo.sql_function, f.to_expr
    assert f.static?
  end

  test "function with static value" do
    klass = new_function('foo', {:type => String})
    f = klass.new(123)
    assert_equal :foo.sql_function(123), f.to_expr
    assert f.static?
  end

  test "function with field" do
    klass = new_function('foo', {:type => String})
    field = stub_field('field', :name => :bar, :ruby_type => {:type => String})
    f = klass.new(field)
    assert_equal :foo.sql_function(:bar), f.to_expr
    assert !f.static?
  end

  test "function with multiple arguments" do
    klass = new_function('foo', {:type => String})
    field = stub_field('field', :name => :bar, :ruby_type => {:type => String})
    f = klass.new(field, 123, 'abc')
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
    field = stub_field('field', :name => :bar, :ruby_type => {:type => String})
    assert_equal :foo.sql_function(:bar), func.new(field).to_expr
    assert_equal :foo.sql_function(:foo.sql_function("hey")), func.new(func.new("hey")).to_expr
  end

  test "invalid parameters" do
    func = new_function('foo', {:type => String}, [[String]])
    assert_raises(TypeError) do
      func.new(123)
    end
    field = stub_field('field', :name => :bar, :ruby_type => {:type => Integer})
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
end
