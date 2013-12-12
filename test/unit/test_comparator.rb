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

  test "registering subclass with score_datasets method instead of score method" do
    klass = new_comparator do
      remove_method :score
      def score_datasets(dataset_1, dataset_2 = nil)
      end
    end
    assert_nothing_raised { Linkage::Comparator.register('foo', klass) }
  end

  test "subclasses required to define score method OR score_datasets method" do
    klass = new_comparator do
      remove_method :score
    end
    assert_raises(ArgumentError) { Linkage::Comparator.register('foo', klass) }
  end

  test "default score_datasets implementation for two datasets" do
    klass = new_comparator
    instance = klass.new
    observer = stub('observer', :update => nil)
    instance.add_observer(observer)

    dataset_1 = stub('dataset 1')
    dataset_1.expects(:each).multiple_yields(
      [(record_1_1 = {:id => 1, :foo => 123})],
      [(record_1_2 = {:id => 2, :foo => 456})]
    )

    dataset_2 = stub('dataset 2')
    dataset_2.expects(:each).twice.multiple_yields(
      [(record_2_1 = {:id => 100, :foo => 123})],
      [(record_2_2 = {:id => 101, :foo => 456})]
    )

    instance.expects(:score).with(record_1_1, record_2_1).returns(1)
    observer.expects(:update).with(record_1_1, record_2_1, 1)
    instance.expects(:score).with(record_1_1, record_2_2).returns(0)
    observer.expects(:update).with(record_1_1, record_2_2, 0)
    instance.expects(:score).with(record_1_2, record_2_1).returns(0)
    observer.expects(:update).with(record_1_2, record_2_1, 0)
    instance.expects(:score).with(record_1_2, record_2_2).returns(1)
    observer.expects(:update).with(record_1_2, record_2_2, 1)

    instance.score_datasets(dataset_1, dataset_2)
  end

  test "default score_datasets implementation for one dataset" do
    klass = new_comparator
    instance = klass.new
    observer = stub('observer', :update => nil)
    instance.add_observer(observer)

    dataset = stub('dataset')
    dataset.expects(:all).returns([
      (record_1 = {:id => 1, :foo => 123}),
      (record_2 = {:id => 2, :foo => 456}),
      (record_3 = {:id => 3, :foo => 456})
    ])

    instance.expects(:score).with(record_1, record_2).returns(0)
    observer.expects(:update).with(record_1, record_2, 0)
    instance.expects(:score).with(record_1, record_3).returns(0)
    observer.expects(:update).with(record_1, record_3, 0)
    instance.expects(:score).with(record_2, record_3).returns(1)
    observer.expects(:update).with(record_2, record_3, 1)

    instance.score_datasets(dataset)
  end
end
