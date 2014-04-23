require File.expand_path("../../test_match_sets", __FILE__)

class UnitTests::TestMatchSets::TestDatabase < Test::Unit::TestCase
  def setup
    @dataset = stub('dataset')
    @database = stub('database', :[] => @dataset)
  end

  test "open_for_writing with filename option" do
    Sequel.expects(:sqlite).with('foo.db').returns(@database)
    match_set = Linkage::MatchSets::Database.new(:filename => 'foo.db')
    @database.stubs(:table_exists?).with(:matches).returns(false)
    @database.expects(:create_table).with(:matches)
    @database.expects(:[]).with(:matches).returns(@dataset)
    match_set.open_for_writing
  end

  test "open_for_writing with default options" do
    Sequel.expects(:sqlite).with('matches.db').returns(@database)
    match_set = Linkage::MatchSets::Database.new
    @database.stubs(:table_exists?).with(:matches).returns(false)
    @database.expects(:create_table).with(:matches)
    @database.expects(:[]).with(:matches).returns(@dataset)
    match_set.open_for_writing
  end

  test "open_for_writing with directory option" do
    expected_directory = File.expand_path('foo')
    FileUtils.expects(:mkdir_p).with(expected_directory)
    expected_filename = File.join(expected_directory, 'matches.db')
    Sequel.expects(:sqlite).with(expected_filename).returns(@database)

    match_set = Linkage::MatchSets::Database.new(:dir => 'foo')
    @database.stubs(:table_exists?).with(:matches).returns(false)
    @database.expects(:create_table).with(:matches)
    @database.expects(:[]).with(:matches).returns(@dataset)
    match_set.open_for_writing
  end

  test "open_for_writing for database with no matches table" do
    match_set = Linkage::MatchSets::Database.new(:conn => @database)
    @database.stubs(:table_exists?).with(:matches).returns(false)
    @database.expects(:create_table).with(:matches)
    @database.expects(:[]).with(:matches).returns(@dataset)
    match_set.open_for_writing
  end

  test "open_for_writing when already open" do
    match_set = Linkage::MatchSets::Database.new(:conn => @database)
    @database.stubs(:table_exists?).with(:matches).returns(false)
    @database.expects(:create_table).with(:matches)
    @database.expects(:[]).with(:matches).returns(@dataset)
    match_set.open_for_writing
    match_set.open_for_writing
  end

  test "open_for_writing when matches table already exists" do
    match_set = Linkage::MatchSets::Database.new(:conn => @database)
    @database.expects(:table_exists?).with(:matches).returns(true)
    @database.expects(:create_table).with(:matches).never
    assert_raises(Linkage::ExistsError) do
      match_set.open_for_writing
    end
  end

  test "open_for_writing when matches table already exists and in overwrite mode" do
    match_set = Linkage::MatchSets::Database.new(:conn => @database, :overwrite => true)
    @database.expects(:drop_table?).with(:matches)
    @database.expects(:create_table).with(:matches)
    @database.expects(:[]).with(:matches).returns(@dataset)
    match_set.open_for_writing
  end

  test "add_match when unopened raises exception" do
    match_set = Linkage::MatchSets::Database.new(:conn => @database)
    assert_raises { match_set.add_match(1, 2, 1) }
  end

  test "add_match" do
    match_set = Linkage::MatchSets::Database.new(:conn => @database)
    @database.stubs(:table_exists?).with(:matches).returns(false)
    @database.stubs(:create_table)
    match_set.open_for_writing

    @dataset.expects(:insert).with({
      :id_1 => 1, :id_2 => 2, :score => 1
    })
    match_set.add_match(1, 2, 1)
  end

  test "registers itself" do
    assert_equal Linkage::MatchSets::Database, Linkage::MatchSet['database']
  end
end
