require 'helper'

class UnitTests::TestComparator < Test::Unit::TestCase
  def setup
    super
    @_comparators = Linkage::Comparator.instance_variable_get("@comparators")
  end

  def teardown
    Linkage::Comparator.instance_variable_set("@comparators", @_comparators)
    super
  end

  test "comparator_name raises error in base class" do
    assert_raises(NotImplementedError) { Linkage::Comparator.comparator_name }
  end

  test "registering subclass requires comparator_name" do
    klass = Class.new(Linkage::Comparator)
    assert_raises(ArgumentError) { Linkage::Comparator.register(klass) }
  end

  test "getting a registered subclass" do
    klass = new_comparator('foo', [[String]], 0..1)
    Linkage::Comparator.register(klass)
    assert_equal klass, Linkage::Comparator['foo']
  end

  test "parameters raises error in base class" do
    assert_raises(NotImplementedError) { Linkage::Comparator.parameters }
  end

  test "subclasses required to define parameters class method" do
    klass = new_comparator('foo')
    assert_raises(ArgumentError) { Linkage::Comparator.register(klass) }
  end

  test "subclasses required to define at least one parameter" do
    klass = new_comparator('foo', [])
    assert_raises(ArgumentError) { Linkage::Comparator.register(klass) }
  end

  test "subclasses required to define score_range class method" do
    klass = new_comparator('foo', [[String]])
    assert_raises(ArgumentError) { Linkage::Comparator.register(klass) }
  end

  test "score_range class should be a Range of two numbers" do
    klass = new_comparator('foo', [[String]], "foo".."bar")
    assert_raises(ArgumentError) { Linkage::Comparator.register(klass) }
  end

  test "subclasses required to define score method" do
    klass = new_comparator('foo', [[String]]) do
      remove_method :score
    end
    assert_raises(ArgumentError) { Linkage::Comparator.register(klass) }
  end

  test "comparator with one valid argument" do
    klass = new_comparator('foo', [[String]])
    meta_object = stub('meta object', :side => :lhs, :ruby_type => { :type => String }, :static? => false)
    f = klass.new(meta_object)
  end

  test "comparator with one invalid argument" do
    klass = new_comparator('foo', [[String]])
    meta_object = stub('meta_object', :ruby_type => { :type => Fixnum }, :static? => false)
    assert_raises(TypeError) { klass.new(meta_object) }
  end

  test "comparator with too few arguments" do
    klass = new_comparator('foo', [[String]])
    assert_raises(ArgumentError) { klass.new }
  end

  test "comparator with too many arguments" do
    klass = new_comparator('foo', [[String]])
    meta_object = stub('meta_object', :ruby_type => { :type => String }, :static? => false)
    assert_raises(ArgumentError) { klass.new(meta_object, meta_object) }
  end

  test "requiring argument to be non-static" do
    klass = new_comparator('foo', [[String, :static => false]])
    meta_object = stub('meta_object', :ruby_type => { :type => String }, :static? => true)
    assert_raise_message("argument 1 was expected to not be static") do
      klass.new(meta_object)
    end
  end

  test "requiring argument to be static" do
    klass = new_comparator('foo', [[String, :static => true]])
    meta_object = stub('meta_object', :ruby_type => { :type => String }, :static? => false)
    assert_raise_message("argument 1 was expected to be static") do
      klass.new(meta_object)
    end
  end

  test "special :any parameter" do
    klass = new_comparator('foo', [[:any]])
    meta_object_1 = stub('meta_object', :side => :lhs, :ruby_type => { :type => String }, :static? => false)
    meta_object_2 = stub('meta_object', :side => :rhs, :ruby_type => { :type => Fixnum }, :static? => false)
    assert_nothing_raised do
      klass.new(meta_object_1)
      klass.new(meta_object_2)
    end
  end

  test "lhs_args" do
    klass = new_comparator('foo', [[String], [String]])
    meta_object_1 = stub('meta object 1', :side => :lhs, :ruby_type => { :type => String }, :static? => false)
    meta_object_2 = stub('meta object 2', :side => :rhs, :ruby_type => { :type => String }, :static? => false)
    obj = klass.new(meta_object_1, meta_object_2)
    assert_equal [meta_object_1], obj.lhs_args
  end

  test "rhs_args" do
    klass = new_comparator('foo', [[String], [String]])
    meta_object_1 = stub('meta object 1', :side => :lhs, :ruby_type => { :type => String }, :static? => false)
    meta_object_2 = stub('meta object 2', :side => :rhs, :ruby_type => { :type => String }, :static? => false)
    obj = klass.new(meta_object_1, meta_object_2)
    assert_equal [meta_object_2], obj.rhs_args
  end
end
