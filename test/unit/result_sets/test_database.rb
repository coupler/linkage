require File.expand_path("../../test_result_sets", __FILE__)

class UnitTests::TestResultSets::TestDatabase < Test::Unit::TestCase
  test "with default options" do
    result_set = Linkage::ResultSets::Database.new

    score_set = stub('score set')
    Linkage::ScoreSets::Database.expects(:new).with({}).returns(score_set)
    assert_same score_set, result_set.score_set

    match_set = stub('match set')
    Linkage::MatchSets::Database.expects(:new).with({}).returns(match_set)
    assert_same match_set, result_set.match_set
  end

  test "with database object" do
    database = stub('database')
    database.stubs(:kind_of?).with(Sequel::Database).returns(true)
    result_set = Linkage::ResultSets::Database.new(database)

    score_set = stub('score set')
    Linkage::ScoreSets::Database.expects(:new).with({:database => database}).returns(score_set)
    assert_same score_set, result_set.score_set

    match_set = stub('match set')
    Linkage::MatchSets::Database.expects(:new).with({:database => database}).returns(match_set)
    assert_same match_set, result_set.match_set
  end

  test "with uri string" do
    database = stub('database')
    Sequel.expects(:connect).with("foo://bar").returns(database)
    result_set = Linkage::ResultSets::Database.new("foo://bar")

    score_set = stub('score set')
    Linkage::ScoreSets::Database.expects(:new).with({:database => database}).returns(score_set)
    assert_same score_set, result_set.score_set

    match_set = stub('match set')
    Linkage::MatchSets::Database.expects(:new).with({:database => database}).returns(match_set)
    assert_same match_set, result_set.match_set
  end

  test "with connect options" do
    database = stub('database')
    Sequel.expects(:connect).with(:foo => 'bar').returns(database)
    result_set = Linkage::ResultSets::Database.new(:foo => 'bar')

    score_set = stub('score set')
    Linkage::ScoreSets::Database.expects(:new).with({:database => database}).returns(score_set)
    assert_same score_set, result_set.score_set

    match_set = stub('match set')
    Linkage::MatchSets::Database.expects(:new).with({:database => database}).returns(match_set)
    assert_same match_set, result_set.match_set
  end

  test "with database options and scores/matches options" do
    opts = {
      :foo => 'bar',
      :scores => {:baz => 'qux'},
      :matches => {:corge => 'grault'}
    }
    database = stub('database')
    Sequel.expects(:connect).with(:foo => 'bar').returns(database)
    result_set = Linkage::ResultSets::Database.new(opts)

    score_set = stub('score set')
    Linkage::ScoreSets::Database.expects(:new).with(opts[:scores].merge(:database => database)).returns(score_set)
    assert_same score_set, result_set.score_set

    match_set = stub('match set')
    Linkage::MatchSets::Database.expects(:new).with(opts[:matches].merge(:database => database)).returns(match_set)
    assert_same match_set, result_set.match_set
  end

  test "registers itself" do
    assert_same Linkage::ResultSets::Database, Linkage::ResultSet['database']
  end
end
