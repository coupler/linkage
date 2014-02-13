require File.expand_path("../../test_score_sets", __FILE__)

class UnitTests::TestScoreSets::TestDatabase < Test::Unit::TestCase
  def setup
    @dataset = stub('dataset')
    @database = stub('database', :[] => @dataset)
  end

  test "open_for_writing for database with no scores table" do
    score_set = Linkage::ScoreSets::Database.new(@database)
    @database.expects(:create_table).with(:scores)
    @database.expects(:[]).with(:scores).returns(@dataset)
    score_set.open_for_writing
  end

  test "open_for_writing when already open" do
    score_set = Linkage::ScoreSets::Database.new(@database)
    @database.expects(:create_table).with(:scores)
    @database.expects(:[]).with(:scores).returns(@dataset)
    score_set.open_for_writing
    score_set.open_for_writing
  end

  test "open_for_reading" do
    score_set = Linkage::ScoreSets::Database.new(@database)
    @database.expects(:[]).with(:scores).returns(@dataset)
    score_set.open_for_reading
  end

  test "open_for_reading when already open" do
    score_set = Linkage::ScoreSets::Database.new(@database)
    @database.expects(:[]).with(:scores).returns(@dataset)
    score_set.open_for_reading
    score_set.open_for_reading
  end

  test "open_for_writing when in read mode raises exception" do
    score_set = Linkage::ScoreSets::Database.new(@database)
    score_set.open_for_reading
    assert_raises(RuntimeError) { score_set.open_for_writing }
  end

  test "open_for_reading when in write mode raises exception" do
    score_set = Linkage::ScoreSets::Database.new(@database)
    @database.stubs(:create_table)
    score_set.open_for_writing
    assert_raises(RuntimeError) { score_set.open_for_reading }
  end

  test "add_score when unopened raises exception" do
    score_set = Linkage::ScoreSets::Database.new(@database)
    assert_raises { score_set.add_score(1, 1, 2, 1) }
  end

  test "add_score when in read mode raises exception" do
    score_set = Linkage::ScoreSets::Database.new(@database)
    score_set.open_for_reading
    assert_raises { score_set.add_score(1, 1, 2, 1) }
  end

  test "add_score" do
    score_set = Linkage::ScoreSets::Database.new(@database)
    @database.stubs(:create_table)
    score_set.open_for_writing

    @dataset.expects(:insert).with({
      :comparator_id => 1, :id_1 => 1, :id_2 => 2, :score => 1
    })
    score_set.add_score(1, 1, 2, 1)
  end

  test "each_pair" do
    score_set = Linkage::ScoreSets::Database.new(@database)
    score_set.open_for_reading

    @dataset.expects(:order).with(:id_1, :id_2, :comparator_id).returns(@dataset)
    @dataset.expects(:each).multiple_yields(
      [{:comparator_id => 1, :id_1 => '1', :id_2 => '2', :score => 1}],
      [{:comparator_id => 2, :id_1 => '1', :id_2 => '2', :score => 0}],
      [{:comparator_id => 1, :id_1 => '2', :id_2 => '3', :score => 1}],
      [{:comparator_id => 2, :id_1 => '2', :id_2 => '3', :score => 1}],
      [{:comparator_id => 1, :id_1 => '3', :id_2 => '4', :score => 0}],
      [{:comparator_id => 2, :id_1 => '3', :id_2 => '4', :score => 1}]
    )
    pairs = []
    score_set.each_pair { |*args| pairs << args }
    assert_equal 3, pairs.length

    pair_1 = pairs.detect { |pair| pair[0] == "1" && pair[1] == "2" }
    assert pair_1
    assert_equal [1, 0], pair_1[2]

    pair_2 = pairs.detect { |pair| pair[0] == "2" && pair[1] == "3" }
    assert pair_2
    assert_equal [1, 1], pair_2[2]

    pair_3 = pairs.detect { |pair| pair[0] == "3" && pair[1] == "4" }
    assert pair_3
    assert_equal [0, 1], pair_3[2]
  end

  test "registers itself" do
    assert_equal Linkage::ScoreSets::Database, Linkage::ScoreSet['database']
  end
end
