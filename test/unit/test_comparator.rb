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

  test "getting a registered subclass" do
    klass = new_comparator
    Linkage::Comparator.register('foo', klass)
    assert_equal klass, Linkage::Comparator['foo']
  end

  test "subclasses required to define score method" do
    klass = new_comparator do
      remove_method :score
    end
    assert_raises(ArgumentError) { Linkage::Comparator.register('foo', klass) }
  end
end
