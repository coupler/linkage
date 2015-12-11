require File.expand_path("../../test_result_sets", __FILE__)

class UnitTests::TestResultSets::TestDatabase < Test::Unit::TestCase
  test "with default options" do
    database = stub('database')
    Sequel.expects(:connect).with(:adapter => :sqlite, :database => 'results.db').returns(database)
    result_set = Linkage::ResultSets::Database.new

    score_set = stub('score set')
    Linkage::ScoreSets::Database.expects(:new).with(database, {}).returns(score_set)
    assert_same score_set, result_set.score_set

    match_set = stub('match set')
    Linkage::MatchSets::Database.expects(:new).with(database, {}).returns(match_set)
    assert_same match_set, result_set.match_set
  end

  test "with database object" do
    database = stub('database')
    Sequel::Database.stubs(:===).with(database).returns(true)
    result_set = Linkage::ResultSets::Database.new(database, {})

    score_set = stub('score set')
    Linkage::ScoreSets::Database.expects(:new).with(database, {}).returns(score_set)
    assert_same score_set, result_set.score_set

    match_set = stub('match set')
    Linkage::MatchSets::Database.expects(:new).with(database, {}).returns(match_set)
    assert_same match_set, result_set.match_set
  end

  test "with uri string" do
    database = stub('database')
    Sequel.expects(:connect).with("foo://bar").returns(database)
    result_set = Linkage::ResultSets::Database.new("foo://bar")

    score_set = stub('score set')
    Linkage::ScoreSets::Database.expects(:new).with(database, {}).returns(score_set)
    assert_same score_set, result_set.score_set

    match_set = stub('match set')
    Linkage::MatchSets::Database.expects(:new).with(database, {}).returns(match_set)
    assert_same match_set, result_set.match_set
  end

  test "with connect options" do
    database = stub('database')
    Sequel.expects(:connect).with(:foo => 'bar').returns(database)
    result_set = Linkage::ResultSets::Database.new(:foo => 'bar')

    score_set = stub('score set')
    Linkage::ScoreSets::Database.expects(:new).with(database, {}).returns(score_set)
    assert_same score_set, result_set.score_set

    match_set = stub('match set')
    Linkage::MatchSets::Database.expects(:new).with(database, {}).returns(match_set)
    assert_same match_set, result_set.match_set
  end

  test "with overwrite option" do
    database = stub('database')
    Sequel.expects(:connect).with(:foo => 'bar').returns(database)
    result_set = Linkage::ResultSets::Database.new({:foo => 'bar'}, {:overwrite => true})

    score_set = stub('score set')
    Linkage::ScoreSets::Database.expects(:new).with(database, {:overwrite => true}).returns(score_set)
    assert_same score_set, result_set.score_set

    match_set = stub('match set')
    Linkage::MatchSets::Database.expects(:new).with(database, {:overwrite => true}).returns(match_set)
    assert_same match_set, result_set.match_set
  end

  test "registers itself" do
    assert_same Linkage::ResultSets::Database, Linkage::ResultSet['database']
  end
end
