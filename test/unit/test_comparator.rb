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

  test "score raises NotImplementedError" do
    comparator = Linkage::Comparator.new
    assert_raises(NotImplementedError) do
      comparator.score(stub('record 1'), stub('record 2'))
    end
  end

  test "score_datasets raises NotImplementedError" do
    comparator = Linkage::Comparator.new
    assert_raises(NotImplementedError) do
      comparator.score_datasets(stub('dataset 1'), stub('dataset 2'))
    end
  end

  test "score_dataset raises NotImplementedError" do
    comparator = Linkage::Comparator.new
    assert_raises(NotImplementedError) do
      comparator.score_dataset(stub('dataset'))
    end
  end

  test "score_and_notify" do
    klass = new_comparator
    instance = klass.new

    observer = stub('observer', :update => nil)
    instance.add_observer(observer)

    record_1 = stub('record 1')
    record_2 = stub('record 2')
    observer.expects(:update).with(instance, record_1, record_2, 1)
    instance.score_and_notify(record_1, record_2)
  end
end
