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
    klass = new_comparator('foo', [[String]])
    Linkage::Comparator.register(klass)
    assert_equal klass, Linkage::Comparator['foo']
  end

  test "subclasses required to define score method" do
    klass = new_comparator('foo', [[String]]) do
      remove_method :score
    end
    assert_raises(ArgumentError) { Linkage::Comparator.register(klass) }
  end
end
