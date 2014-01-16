require 'helper'

class UnitTests::TestCompare < Test::Unit::TestCase
  def self.const_missing(name)
    if Linkage::Comparators.const_defined?(name)
      Linkage::Comparators.const_get(name)
    else
      super
    end
  end

  test "subclass of Comparator" do
    assert_equal Linkage::Comparator, Compare.superclass
  end

  test "score for not equal to" do
    field_1 = stub('foo field', :name => :foo, :ruby_type => { :type => Integer })
    field_2 = stub('bar field', :name => :bar, :ruby_type => { :type => Integer })
    comp = Compare.new([field_1], [field_2], :not_equal)
    assert_equal :simple, comp.type
    assert_equal 1, comp.score({:foo => 10}, {:bar => 5})
    assert_equal 0, comp.score({:foo => 5}, {:bar => 5})
    assert_equal 1, comp.score({:foo => 0}, {:bar => 5})
  end

  test "score for greater than" do
    field_1 = stub('foo field', :name => :foo, :ruby_type => { :type => Integer })
    field_2 = stub('bar field', :name => :bar, :ruby_type => { :type => Integer })
    comp = Compare.new([field_1], [field_2], :greater_than)
    assert_equal :simple, comp.type
    assert_equal 1, comp.score({:foo => 10}, {:bar => 5})
    assert_equal 0, comp.score({:foo => 5}, {:bar => 5})
    assert_equal 0, comp.score({:foo => 0}, {:bar => 5})
  end

  test "score for greater than or equal to" do
    field_1 = stub('foo field', :name => :foo, :ruby_type => { :type => Integer })
    field_2 = stub('bar field', :name => :bar, :ruby_type => { :type => Integer })
    comp = Compare.new([field_1], [field_2], :greater_than_or_equal_to)
    assert_equal :simple, comp.type
    assert_equal 1, comp.score({:foo => 10}, {:bar => 5})
    assert_equal 1, comp.score({:foo => 5}, {:bar => 5})
    assert_equal 0, comp.score({:foo => 0}, {:bar => 5})
  end

  test "score for less than or equal to" do
    field_1 = stub('foo field', :name => :foo, :ruby_type => { :type => Integer })
    field_2 = stub('bar field', :name => :bar, :ruby_type => { :type => Integer })
    comp = Compare.new([field_1], [field_2], :less_than_or_equal_to)
    assert_equal :simple, comp.type
    assert_equal 0, comp.score({:foo => 10}, {:bar => 5})
    assert_equal 1, comp.score({:foo => 5}, {:bar => 5})
    assert_equal 1, comp.score({:foo => 0}, {:bar => 5})
  end

  test "score for less than" do
    field_1 = stub('foo field', :name => :foo, :ruby_type => { :type => Integer })
    field_2 = stub('bar field', :name => :bar, :ruby_type => { :type => Integer })
    comp = Compare.new([field_1], [field_2], :less_than)
    assert_equal :simple, comp.type
    assert_equal 0, comp.score({:foo => 10}, {:bar => 5})
    assert_equal 0, comp.score({:foo => 5}, {:bar => 5})
    assert_equal 1, comp.score({:foo => 0}, {:bar => 5})
  end

  test "score_datasets with one field equality" do
    field_1 = stub('foo field', :name => :foo, :ruby_type => { :type => Integer })
    field_2 = stub('bar field', :name => :bar, :ruby_type => { :type => Integer })
    comp = Compare.new([field_1], [field_2], :equal_to)
    assert_equal :advanced, comp.type
    observer = stub('observer', :update => nil)
    comp.add_observer(observer)

    dataset_1 = stub('dataset 1')
    dataset_1.expects(:order).with(:foo).returns(dataset_1)
    dataset_1.expects(:each).multiple_yields(
      [(record_1_1 = {:id => 1, :foo => 123})],
      [(record_1_2 = {:id => 2, :foo => 456})],
      [(record_1_3 = {:id => 3, :foo => 456})]
    )

    dataset_2 = stub('dataset 2')
    dataset_2.expects(:order).with(:bar).returns(dataset_2)
    dataset_2.expects(:each).multiple_yields(
      [(record_2_1 = {:id => 100, :bar => 123})],
      [(record_2_2 = {:id => 101, :bar => 456})],
      [(record_2_3 = {:id => 102, :bar => 456})]
    )

    observer.expects(:update).with(comp, record_1_1, record_2_1, 1)
    observer.expects(:update).with(comp, record_1_2, record_2_2, 1)
    observer.expects(:update).with(comp, record_1_2, record_2_3, 1)
    observer.expects(:update).with(comp, record_1_3, record_2_2, 1)
    observer.expects(:update).with(comp, record_1_3, record_2_3, 1)

    comp.score_datasets(dataset_1, dataset_2)
  end

  test "score_datasets with multiple field equality" do
    field_1_1 = stub('foo field', :name => :foo, :ruby_type => { :type => Integer })
    field_1_2 = stub('bar field', :name => :bar, :ruby_type => { :type => Integer })
    field_2_1 = stub('baz field', :name => :baz, :ruby_type => { :type => Integer })
    field_2_2 = stub('qux field', :name => :qux, :ruby_type => { :type => Integer })
    comp = Compare.new([field_1_1, field_1_2], [field_2_1, field_2_2], :equal_to)
    assert_equal :advanced, comp.type
    observer = stub('observer', :update => nil)
    comp.add_observer(observer)

    dataset_1 = stub('dataset 1')
    dataset_1.expects(:order).with(:foo, :bar).returns(dataset_1)
    dataset_1.expects(:each).multiple_yields(
      [(record_1_1 = {:id => 1, :foo => 123, :bar => 123})],
      [(record_1_2 = {:id => 2, :foo => 123, :bar => 456})],
      [(record_1_3 = {:id => 3, :foo => 123, :bar => 789})],
      [(record_1_4 = {:id => 4, :foo => 456, :bar => 123})]
    )

    dataset_2 = stub('dataset 2')
    dataset_2.expects(:order).with(:baz, :qux).returns(dataset_2)
    dataset_2.expects(:each).multiple_yields(
      [(record_2_1 = {:id => 100, :baz => 123, :qux => 123})],
      [(record_2_2 = {:id => 101, :baz => 123, :qux => 123})],
      [(record_2_3 = {:id => 102, :baz => 123, :qux => 789})],
      [(record_2_4 = {:id => 103, :baz => 456, :qux => 123})],
      [(record_2_5 = {:id => 104, :baz => 456, :qux => 456})]
    )

    observer.expects(:update).with(comp, record_1_1, record_2_1, 1)
    observer.expects(:update).with(comp, record_1_1, record_2_2, 1)
    observer.expects(:update).with(comp, record_1_3, record_2_3, 1)
    observer.expects(:update).with(comp, record_1_4, record_2_4, 1)

    comp.score_datasets(dataset_1, dataset_2)
  end

  test "score_dataset with same single field equality" do
    field = stub('foo field', :name => :foo, :ruby_type => { :type => Integer })
    comp = Compare.new([field], [field], :equal_to)
    assert_equal :advanced, comp.type
    observer = stub('observer', :update => nil)
    comp.add_observer(observer)

    dataset = stub('dataset')
    dataset.expects(:order).with(:foo).returns(dataset)
    dataset.expects(:each).multiple_yields(
      [(record_1 = {:id => 1, :foo => 123})],
      [(record_2 = {:id => 2, :foo => 456})],
      [(record_3 = {:id => 3, :foo => 456})]
    )

    observer.expects(:update).with(comp, record_2, record_3, 1)
    comp.score_dataset(dataset)
  end

  test "score_dataset with same multiple field equality" do
    field_1 = stub('foo field', :name => :foo, :ruby_type => { :type => Integer })
    field_2 = stub('bar field', :name => :bar, :ruby_type => { :type => Integer })
    comp = Compare.new([field_1, field_2], [field_1, field_2], :equal_to)
    assert_equal :advanced, comp.type
    observer = stub('observer', :update => nil)
    comp.add_observer(observer)

    dataset = stub('dataset')
    dataset.expects(:order).with(:foo, :bar).returns(dataset)
    dataset.expects(:each).multiple_yields(
      [(record_1 = {:id => 1, :foo => 123, :bar => 123})],
      [(record_2 = {:id => 2, :foo => 123, :bar => 123})],
      [(record_3 = {:id => 3, :foo => 123, :bar => 123})],
      [(record_4 = {:id => 4, :foo => 123, :bar => 456})],
      [(record_5 = {:id => 5, :foo => 456, :bar => 123})],
      [(record_6 = {:id => 6, :foo => 456, :bar => 456})],
      [(record_7 = {:id => 7, :foo => 456, :bar => 456})]
    )

    observer.expects(:update).with(comp, record_1, record_2, 1)
    observer.expects(:update).with(comp, record_1, record_3, 1)
    observer.expects(:update).with(comp, record_2, record_3, 1)
    observer.expects(:update).with(comp, record_6, record_7, 1)

    comp.score_dataset(dataset)
  end

  test "score_dataset with different single field equality" do
    field_1 = stub('foo field', :name => :foo, :ruby_type => { :type => Integer })
    field_2 = stub('bar field', :name => :bar, :ruby_type => { :type => Integer })
    comp = Compare.new([field_1], [field_2], :equal_to)
    assert_equal :advanced, comp.type
    observer = stub('observer', :update => nil)
    comp.add_observer(observer)

    dataset = stub('dataset')
    dataset_1 = stub('dataset 1')
    dataset.expects(:order).with(:foo).returns(dataset_1)
    dataset_1.expects(:each).multiple_yields(
      [(record_1 = {:id => 1, :foo => 123, :bar => 456})],
      [(record_2 = {:id => 2, :foo => 456, :bar => 456})],
      [(record_3 = {:id => 3, :foo => 456, :bar => 123})]
    )

    dataset_2 = stub('dataset 2')
    dataset.expects(:order).with(:bar).returns(dataset_2)
    dataset_2.expects(:each).multiple_yields(
      [record_3],
      [record_1],
      [record_2]
    )

    observer.expects(:update).with(comp, record_1, record_3, 1)
    observer.expects(:update).with(comp, record_2, record_1, 1)
    observer.expects(:update).with(comp, record_2, record_2, 1)
    observer.expects(:update).with(comp, record_3, record_1, 1)
    observer.expects(:update).with(comp, record_3, record_2, 1)

    comp.score_dataset(dataset)
  end

  test "registers itself" do
    assert_equal Compare, Linkage::Comparator['compare']
  end

  test "requires equal size sets" do
    field_1 = stub('foo field', :name => :foo, :ruby_type => { :type => Integer })
    field_2 = stub('bar field', :name => :bar, :ruby_type => { :type => Integer })
    assert_raises do
      Compare.new([field_1, field_2], [], :greater_than_or_equal_to)
    end
  end

  test "requires that sets have values with alike types" do
    field_1 = stub('foo field', :name => :foo, :ruby_type => { :type => Integer })
    field_2 = stub('bar field', :name => :bar, :ruby_type => { :type => Date })
    assert_raises do
      Compare.new([field_1], [field_2], :greater_than_or_equal_to)
    end
  end

  test "requires valid operation" do
    field_1 = stub('foo field', :name => :foo, :ruby_type => { :type => Integer })
    field_2 = stub('bar field', :name => :bar, :ruby_type => { :type => Integer })
    assert_raises do
      Compare.new([field_1], [field_2], 'foo')
    end
  end
end
