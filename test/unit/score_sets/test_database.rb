require File.expand_path("../../test_score_sets", __FILE__)

class UnitTests::TestScoreSets::TestDatabase < Test::Unit::TestCase
  def setup
    @dataset = stub('dataset')
    @database = stub('database', :[] => @dataset)
    Sequel::Database.stubs(:===).with(@database).returns(true)
  end

  test "open_for_writing with uri string" do
    Sequel.expects(:connect).with('foo://bar').returns(@database)
    score_set = Linkage::ScoreSets::Database.new('foo://bar')
    @database.stubs(:table_exists?).with(:scores).returns(false)
    @database.expects(:create_table).with(:scores)
    @database.expects(:[]).with(:scores).returns(@dataset)
    score_set.open_for_writing
  end

  test "open_for_writing with database object" do
    score_set = Linkage::ScoreSets::Database.new(@database)
    @database.stubs(:table_exists?).with(:scores).returns(false)
    @database.expects(:create_table).with(:scores)
    @database.expects(:[]).with(:scores).returns(@dataset)
    score_set.open_for_writing
  end

  test "open_for_writing with filename option" do
    Sequel.expects(:connect).with(:adapter => :sqlite, :database => 'foo.db').returns(@database)
    score_set = Linkage::ScoreSets::Database.new(:filename => 'foo.db')
    @database.stubs(:table_exists?).with(:scores).returns(false)
    @database.expects(:create_table).with(:scores)
    @database.expects(:[]).with(:scores).returns(@dataset)
    score_set.open_for_writing
  end

  test "open_for_writing with default options" do
    Sequel.expects(:connect).with(:adapter => :sqlite, :database => 'scores.db').returns(@database)
    score_set = Linkage::ScoreSets::Database.new
    @database.stubs(:table_exists?).with(:scores).returns(false)
    @database.expects(:create_table).with(:scores)
    @database.expects(:[]).with(:scores).returns(@dataset)
    score_set.open_for_writing
  end

  test "open_for_writing with directory option" do
    expected_directory = File.expand_path('foo')
    FileUtils.expects(:mkdir_p).with(expected_directory)
    expected_filename = File.join(expected_directory, 'scores.db')
    Sequel.expects(:connect).with(:adapter => :sqlite, :database => expected_filename).returns(@database)
    score_set = Linkage::ScoreSets::Database.new(:dir => 'foo')
    @database.stubs(:table_exists?).with(:scores).returns(false)
    @database.expects(:create_table).with(:scores)
    @database.expects(:[]).with(:scores).returns(@dataset)
    score_set.open_for_writing
  end

  test "open_for_writing for database with no scores table" do
    score_set = Linkage::ScoreSets::Database.new(@database)
    @database.stubs(:table_exists?).with(:scores).returns(false)
    @database.expects(:create_table).with(:scores)
    @database.expects(:[]).with(:scores).returns(@dataset)
    score_set.open_for_writing
  end

  test "open_for_writing when already open" do
    score_set = Linkage::ScoreSets::Database.new(@database)
    @database.stubs(:table_exists?).with(:scores).returns(false)
    @database.expects(:create_table).with(:scores)
    @database.expects(:[]).with(:scores).returns(@dataset)
    score_set.open_for_writing
    score_set.open_for_writing
  end

  test "open_for_writing when scores table already exists" do
    score_set = Linkage::ScoreSets::Database.new(@database)
    @database.expects(:table_exists?).with(:scores).returns(true)
    @database.expects(:create_table).with(:scores).never
    assert_raises(Linkage::ExistsError) do
      score_set.open_for_writing
    end
  end

  test "open_for_writing when scores table already exists and in overwrite mode" do
    score_set = Linkage::ScoreSets::Database.new(@database, :overwrite => true)
    @database.expects(:drop_table?).with(:scores)
    @database.expects(:create_table).with(:scores)
    @database.expects(:[]).with(:scores).returns(@dataset)
    score_set.open_for_writing
  end

  test "open_for_reading" do
    score_set = Linkage::ScoreSets::Database.new(@database)
    @database.stubs(:table_exists?).with(:scores).returns(true)
    @database.expects(:[]).with(:scores).returns(@dataset)
    score_set.open_for_reading
  end

  test "open_for_reading when already open" do
    score_set = Linkage::ScoreSets::Database.new(@database)
    @database.stubs(:table_exists?).with(:scores).returns(true)
    @database.expects(:[]).with(:scores).returns(@dataset)
    score_set.open_for_reading
    score_set.open_for_reading
  end

  test "open_for_reading when table is missing" do
    score_set = Linkage::ScoreSets::Database.new(@database)
    @database.expects(:table_exists?).with(:scores).returns(false)
    @database.expects(:[]).with(:scores).returns(@dataset).never
    assert_raises(Linkage::MissingError) do
      score_set.open_for_reading
    end
  end

  test "open_for_writing when in read mode raises exception" do
    score_set = Linkage::ScoreSets::Database.new(@database)
    @database.stubs(:table_exists?).with(:scores).returns(true)
    score_set.open_for_reading
    assert_raises(RuntimeError) { score_set.open_for_writing }
  end

  test "open_for_reading when in write mode raises exception" do
    score_set = Linkage::ScoreSets::Database.new(@database)
    @database.stubs(:table_exists?).with(:scores).returns(false)
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
    @database.stubs(:table_exists?).with(:scores).returns(true)
    score_set.open_for_reading
    assert_raises { score_set.add_score(1, 1, 2, 1) }
  end

  test "add_score" do
    score_set = Linkage::ScoreSets::Database.new(@database)
    @database.stubs(:table_exists?).with(:scores).returns(false)
    @database.stubs(:create_table)
    score_set.open_for_writing

    @dataset.expects(:insert).with({
      :comparator_id => 1, :id_1 => 1, :id_2 => 2, :score => 1
    })
    score_set.add_score(1, 1, 2, 1)
  end

  test "each_pair" do
    score_set = Linkage::ScoreSets::Database.new(@database)
    @database.stubs(:table_exists?).with(:scores).returns(true)

    @dataset.expects(:order).with(:id_1, :id_2, :comparator_id).returns(@dataset)
    @dataset.expects(:each).multiple_yields(
      [{:comparator_id => 1, :id_1 => '1', :id_2 => '2', :score => 0.5}],
      [{:comparator_id => 2, :id_1 => '1', :id_2 => '2', :score => 0}],
      [{:comparator_id => 1, :id_1 => '2', :id_2 => '3', :score => 1}],
      [{:comparator_id => 2, :id_1 => '2', :id_2 => '3', :score => 1}],
      [{:comparator_id => 1, :id_1 => '3', :id_2 => '4', :score => 0}],
      [{:comparator_id => 2, :id_1 => '3', :id_2 => '4', :score => 1}],
      [{:comparator_id => 3, :id_1 => '4', :id_2 => '5', :score => 0}]
    )
    pairs = []
    score_set.open_for_reading
    score_set.each_pair { |*args| pairs << args }
    score_set.close
    assert_equal 4, pairs.length

    pair_1 = pairs.detect { |pair| pair[0] == "1" && pair[1] == "2" }
    assert pair_1
    expected_1 = {1 => 0.5, 2 => 0}
    assert_equal expected_1, pair_1[2]

    pair_2 = pairs.detect { |pair| pair[0] == "2" && pair[1] == "3" }
    assert pair_2
    expected_2 = {1 => 1, 2 => 1}
    assert_equal expected_2, pair_2[2]

    pair_3 = pairs.detect { |pair| pair[0] == "3" && pair[1] == "4" }
    assert pair_3
    expected_3 = {1 => 0, 2 => 1}
    assert_equal expected_3, pair_3[2]

    pair_4 = pairs.detect { |pair| pair[0] == "4" && pair[1] == "5" }
    assert pair_3
    expected_4 = {3 => 0}
    assert_equal expected_4, pair_4[2]
  end

  test "each_pair when not open for reading" do
    score_set = Linkage::ScoreSets::Database.new(@database)
    assert_raise_message("not in read mode") do
      score_set.each_pair { |*args| }
    end
  end

  test "registers itself" do
    assert_equal Linkage::ScoreSets::Database, Linkage::ScoreSet['database']
  end
end
