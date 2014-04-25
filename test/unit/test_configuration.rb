require 'helper'

class UnitTests::TestConfiguration < Test::Unit::TestCase
  def setup
    @pk_1 = stub('primary key 1', :name => :id)
    @field_1 = stub('field 1')
    @field_set_1 = stub('field set 1', :primary_key => @pk_1, :[] => @field_1)
    @dataset_1 = stub_dataset(:field_set => @field_set_1)
    @pk_2 = stub('primary key 2', :name => :id)
    @field_2 = stub('field 2')
    @field_set_2 = stub('field set 2', :primary_key => @pk_2, :[] => @field_2)
    @dataset_2 = stub_dataset(:field_set => @field_set_2)
    @score_set = stub_instance(Linkage::ScoreSet)
    @match_set = stub('match set')
    @result_set = stub('result set', :score_set => @score_set, :match_set => @match_set)
    @compare = stub('compare')
    Linkage::Comparators::Compare.stubs(:new).returns(@compare)
  end

  test "init with single dataset and result set" do
    config = Linkage::Configuration.new(@dataset_1, @result_set)
    assert_equal @dataset_1, config.dataset_1
    assert_nil config.dataset_2
    assert_equal @result_set, config.result_set
  end

  test "init with single dataset, score set, and match set" do
    Linkage::ResultSet.expects(:new).with(@score_set, @match_set).returns(@result_set)
    config = Linkage::Configuration.new(@dataset_1, @score_set, @match_set)
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

  test "init with two datasets, score set, and match set" do
    Linkage::ResultSet.expects(:new).with(@score_set, @match_set).returns(@result_set)
    config = Linkage::Configuration.new(@dataset_1, @dataset_2, @score_set, @match_set)
    assert_equal @dataset_1, config.dataset_1
    assert_equal @dataset_2, config.dataset_2
    assert_equal @result_set, config.result_set
  end

  test "adding comparator with set arguments and two datasets" do
    config = Linkage::Configuration.new(@dataset_1, @dataset_2, @result_set)

    @field_set_1.expects(:[]).with(:foo).returns(@field_1)
    @field_set_2.expects(:[]).with(:foo).returns(@field_2)
    Linkage::Comparators::Compare.expects(:new).with([@field_1], [@field_2], :equal).returns(@compare)
    comp = config.compare([:foo], [:foo], :equal)
    assert_equal @compare, config.comparators[0]
    assert_equal config.comparators[0], comp
  end

  test "adding comparator with set arguments and one datasets" do
    config = Linkage::Configuration.new(@dataset_1, @result_set)

    @field_set_1.expects(:[]).with(:foo).returns(@field_1)
    @field_set_1.expects(:[]).with(:bar).returns(@field_2)
    Linkage::Comparators::Compare.expects(:new).with([@field_1], [@field_2], :equal).returns(@compare)
    comp = config.compare([:foo], [:bar], :equal)
    assert_equal @compare, config.comparators[0]
    assert_equal config.comparators[0], comp
  end

  test "adding comparator with scalar arguments and two datasets" do
    config = Linkage::Configuration.new(@dataset_1, @dataset_2, @result_set)

    @field_set_1.expects(:[]).with(:foo).returns(@field_1)
    @field_set_2.expects(:[]).with(:foo).returns(@field_2)
    within = stub('within')
    Linkage::Comparators::Within.expects(:new).with(@field_1, @field_2, 5).returns(within)
    comp = config.within(:foo, :foo, 5)
    assert_equal within, config.comparators[0]
    assert_equal config.comparators[0], comp
  end

  test "score_recorder with two datasets" do
    config = Linkage::Configuration.new(@dataset_1, @dataset_2, @result_set)
    config.compare([:foo], [:foo], :equal)

    @field_set_1.expects(:primary_key).returns(@pk_1)
    @field_set_2.expects(:primary_key).returns(@pk_2)
    @pk_1.expects(:name).returns(:id_1)
    @pk_2.expects(:name).returns(:id_2)
    score_recorder = stub('recorder')
    Linkage::ScoreRecorder.expects(:new).with([@compare], @score_set, [:id_1, :id_2]).returns(score_recorder)
    assert_same score_recorder, config.score_recorder
  end

  test "score_recorder with one dataset" do
    config = Linkage::Configuration.new(@dataset_1, @result_set)
    config.compare([:foo], [:bar], :equal)

    @field_set_1.expects(:primary_key).returns(@pk_1)
    @pk_1.expects(:name).returns(:id_1)
    score_recorder = stub('score recorder')
    Linkage::ScoreRecorder.expects(:new).with([@compare], @score_set, [:id_1, :id_1]).returns(score_recorder)
    assert_same score_recorder, config.score_recorder
  end

  test "default matcher" do
    config = Linkage::Configuration.new(@dataset_1, @dataset_2, @result_set)
    config.compare([:foo], [:bar], :equal)

    matcher = stub('matcher')
    Linkage::Matcher.expects(:new).with([@compare], @score_set, :mean, 0.5).returns(matcher)
    assert_equal matcher, config.matcher
  end

  test "matcher with explicit algorithm" do
    config = Linkage::Configuration.new(@dataset_1, @dataset_2, @result_set)
    config.compare([:foo], [:bar], :equal)
    config.algorithm = :foo

    matcher = stub('matcher')
    Linkage::Matcher.expects(:new).with([@compare], @score_set, :foo, 0.5).returns(matcher)
    assert_equal matcher, config.matcher
  end

  test "matcher with explicit threshold" do
    config = Linkage::Configuration.new(@dataset_1, @dataset_2, @result_set)
    config.compare([:foo], [:bar], :equal)
    config.threshold = 0.9

    matcher = stub('matcher')
    Linkage::Matcher.expects(:new).with([@compare], @score_set, :mean, 0.9).returns(matcher)
    assert_equal matcher, config.matcher
  end

  test "match_recorder" do
    config = Linkage::Configuration.new(@dataset_1, @dataset_2, @result_set)

    matcher = stub('matcher')
    match_recorder = stub('match recorder')
    Linkage::MatchRecorder.expects(:new).with(matcher, @match_set).returns(match_recorder)
    assert_equal match_recorder, config.match_recorder(matcher)
  end
end
