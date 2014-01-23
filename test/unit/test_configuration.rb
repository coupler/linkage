require 'helper'

class UnitTests::TestConfiguration < Test::Unit::TestCase
  def setup
    @pk_1 = stub('primary key 1', :name => :id)
    @field_set_1 = stub('field set 1', :primary_key => @pk_1)
    @dataset_1 = stub('dataset 1', :field_set => @field_set_1)
    @pk_2 = stub('primary key 2', :name => :id)
    @field_set_2 = stub('field set 2', :primary_key => @pk_2)
    @dataset_2 = stub('dataset 2', :field_set => @field_set_2)
    @result_set = stub('result set')
  end

  test "init with single dataset and result set" do
    config = Linkage::Configuration.new(@dataset_1, @result_set)
    assert_equal @dataset_1, config.dataset_1
    assert_nil config.dataset_2
    assert_equal @result_set, config.result_set
  end

  test "init with two datasets and result set" do
    config = Linkage::Configuration.new(@dataset_1, @dataset_2, @result_set)
    assert_equal @dataset_1, config.dataset_1
    assert_equal @dataset_2, config.dataset_2
    assert_equal @result_set, config.result_set
  end

  test "adding comparator with set arguments and two datasets" do
    config = Linkage::Configuration.new(@dataset_1, @dataset_2, @result_set)

    field_1 = stub('field 1')
    @field_set_1.expects(:[]).with(:foo).returns(field_1)
    field_2 = stub('field 2')
    @field_set_2.expects(:[]).with(:foo).returns(field_2)
    compare = stub('compare')
    Linkage::Comparators::Compare.expects(:new).with([field_1], [field_2], :equal_to).returns(compare)
    compare.expects(:add_observer).with(config, :add_score)
    config.compare([:foo], [:foo], :equal_to)
    assert_equal compare, config.comparators[0]
  end

  test "adding comparator with set arguments and one datasets" do
    config = Linkage::Configuration.new(@dataset_1, @result_set)

    field_1 = stub('field 1')
    @field_set_1.expects(:[]).with(:foo).returns(field_1)
    field_2 = stub('field 2')
    @field_set_1.expects(:[]).with(:bar).returns(field_2)
    compare = stub('compare')
    Linkage::Comparators::Compare.expects(:new).with([field_1], [field_2], :equal_to).returns(compare)
    compare.expects(:add_observer).with(config, :add_score)
    config.compare([:foo], [:bar], :equal_to)
    assert_equal compare, config.comparators[0]
  end

  test "adding comparator with scalar arguments and two datasets" do
    config = Linkage::Configuration.new(@dataset_1, @dataset_2, @result_set)

    field_1 = stub('field 1')
    @field_set_1.expects(:[]).with(:foo).returns(field_1)
    field_2 = stub('field 2')
    @field_set_2.expects(:[]).with(:foo).returns(field_2)
    within = stub('within')
    Linkage::Comparators::Within.expects(:new).with(field_1, field_2, 5).returns(within)
    within.expects(:add_observer).with(config, :add_score)
    config.within(:foo, :foo, 5)
    assert_equal within, config.comparators[0]
  end

  test "recorder with two datasets" do
    config = Linkage::Configuration.new(@dataset_1, @dataset_2, @result_set)

    field_1 = stub('field 1')
    @field_set_1.stubs(:[]).with(:foo).returns(field_1)
    field_2 = stub('field 2')
    @field_set_2.stubs(:[]).with(:foo).returns(field_2)
    compare = stub('compare', :add_observer => nil)
    Linkage::Comparators::Compare.stubs(:new).with([field_1], [field_2], :equal_to).returns(compare)
    config.compare([:foo], [:foo], :equal_to)

    @field_set_1.expects(:primary_key).returns(@pk_1)
    @field_set_2.expects(:primary_key).returns(@pk_2)
    @pk_1.expects(:name).returns(:id_1)
    @pk_2.expects(:name).returns(:id_2)
    recorder = stub('recorder')
    Linkage::Recorder.expects(:new).with(@result_set, [:id_1, :id_2]).returns(recorder)
    assert_same recorder, config.recorder
  end

  test "recorder with one dataset" do
    config = Linkage::Configuration.new(@dataset_1, @result_set)

    field_1 = stub('field 1')
    @field_set_1.stubs(:[]).with(:foo).returns(field_1)
    field_2 = stub('field 2')
    @field_set_1.stubs(:[]).with(:bar).returns(field_2)
    compare = stub('compare', :add_observer => nil)
    Linkage::Comparators::Compare.stubs(:new).with([field_1], [field_2], :equal_to).returns(compare)
    config.compare([:foo], [:bar], :equal_to)

    @field_set_1.expects(:primary_key).returns(@pk_1)
    @pk_1.expects(:name).returns(:id_1)
    recorder = stub('recorder')
    Linkage::Recorder.expects(:new).with(@result_set, [:id_1, :id_1]).returns(recorder)
    assert_same recorder, config.recorder
  end
end
