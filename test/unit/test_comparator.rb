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

  test "default subclass has type of simple" do
    klass = new_comparator
    instance = klass.new
    assert_equal :simple, instance.type
  end

  test "getting a registered subclass" do
    klass = new_comparator
    Linkage::Comparator.register('foo', klass)
    assert_equal klass, Linkage::Comparator['foo']
  end

  test "registering subclass with advanced scoring methods" do
    klass = new_comparator do
      remove_method :score

      def score_datasets(dataset_1, dataset_2)
      end

      def score_dataset(dataset)
      end
    end
    assert_nothing_raised { Linkage::Comparator.register('foo', klass) }
  end

  test "subclasses required to define either simple or advanced scoring methods" do
    klass = new_comparator do
      remove_method :score
    end
    assert_raises(ArgumentError) { Linkage::Comparator.register('foo', klass) }

    klass = new_comparator do
      remove_method :score

      def score_datasets(dataset_1, dataset_2)
      end
    end
    assert_raises(ArgumentError) { Linkage::Comparator.register('foo', klass) }
  end
end
