require 'helper'

class UnitTests::TestSingleThreadedRunner < Test::Unit::TestCase
  test "subclass of Runner" do
    assert_equal Linkage::Runner, Linkage::SingleThreadedRunner.superclass
  end

  sub_test_case('two datasets') do
    def setup
      @dataset_1 = stub('dataset 1')
      @dataset_2 = stub('dataset 2')
      @config = stub('config', :dataset_1 => @dataset_1, :dataset_2 => @dataset_2)
      @runner = Linkage::SingleThreadedRunner.new(@config)
    end

    test "execute simple comparisons" do
      comparator_1 = stub('comparator 1', :type => :simple)
      comparator_2 = stub('comparator 2', :type => :simple)
      @config.stubs(:comparators).returns([comparator_1, comparator_2])

      @dataset_1.expects(:each).multiple_yields(
        [(record_1_1 = {:id => 1, :foo => 123})],
        [(record_1_2 = {:id => 2, :foo => 456})]
      )
      @dataset_2.expects(:each).twice.multiple_yields(
        [(record_2_1 = {:id => 100, :foo => 123})],
        [(record_2_2 = {:id => 101, :foo => 456})]
      )

      comparator_1.expects(:score_and_notify).with(record_1_1, record_2_1)
      comparator_2.expects(:score_and_notify).with(record_1_1, record_2_1)
      comparator_1.expects(:score_and_notify).with(record_1_1, record_2_2)
      comparator_2.expects(:score_and_notify).with(record_1_1, record_2_2)
      comparator_1.expects(:score_and_notify).with(record_1_2, record_2_1)
      comparator_2.expects(:score_and_notify).with(record_1_2, record_2_1)
      comparator_1.expects(:score_and_notify).with(record_1_2, record_2_2)
      comparator_2.expects(:score_and_notify).with(record_1_2, record_2_2)

      @runner.execute
    end

    test "execute advanced comparisons" do
      comparator_1 = stub('comparator 1', :type => :advanced)
      comparator_2 = stub('comparator 2', :type => :advanced)
      @config.stubs(:comparators).returns([comparator_1, comparator_2])

      comparator_1.expects(:score_datasets).with(@dataset_1, @dataset_2)
      comparator_2.expects(:score_datasets).with(@dataset_1, @dataset_2)
      @runner.execute
    end
  end

  sub_test_case('one dataset') do
    def setup
      @dataset = stub('dataset')
      @config = stub('config', :dataset_1 => @dataset, :dataset_2 => nil)
      @runner = Linkage::SingleThreadedRunner.new(@config)
    end

    test "execute simple comparisons" do
      comparator_1 = stub('comparator 1', :type => :simple)
      comparator_2 = stub('comparator 2', :type => :simple)
      @config.stubs(:comparators).returns([comparator_1, comparator_2])

      @dataset.expects(:all).returns([
        (record_1 = {:id => 1, :foo => 123}),
        (record_2 = {:id => 2, :foo => 456}),
        (record_3 = {:id => 3, :foo => 456})
      ])

      comparator_1.expects(:score_and_notify).with(record_1, record_2)
      comparator_2.expects(:score_and_notify).with(record_1, record_2)
      comparator_1.expects(:score_and_notify).with(record_1, record_3)
      comparator_2.expects(:score_and_notify).with(record_1, record_3)
      comparator_1.expects(:score_and_notify).with(record_2, record_3)
      comparator_2.expects(:score_and_notify).with(record_2, record_3)

      @runner.execute
    end

    test "execute advanced comparisons" do
      comparator_1 = stub('comparator 1', :type => :advanced)
      comparator_2 = stub('comparator 2', :type => :advanced)
      @config.stubs(:comparators).returns([comparator_1, comparator_2])

      comparator_1.expects(:score_dataset).with(@dataset)
      comparator_2.expects(:score_dataset).with(@dataset)
      @runner.execute
    end
  end
end
