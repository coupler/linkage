require File.expand_path("../../test_result_sets", __FILE__)

class UnitTests::TestResultSets::TestCSV < Test::Unit::TestCase
  def setup
    @tmpdir = Dir.mktmpdir('linkage')
  end

  def teardown
    FileUtils.remove_entry_secure(@tmpdir)
  end

  test "default options" do
    result_set = Linkage::ResultSets::CSV.new

    score_set = stub('score set')
    Linkage::ScoreSets::CSV.expects(:new).with({}).returns(score_set)
    assert_same score_set, result_set.score_set

    match_set = stub('match set')
    Linkage::MatchSets::CSV.expects(:new).with({}).returns(match_set)
    assert_same match_set, result_set.match_set
  end

  test "directory option" do
    result_set = Linkage::ResultSets::CSV.new(:dir => 'foo')

    score_set = stub('score set')
    Linkage::ScoreSets::CSV.expects(:new).with({:dir => 'foo'}).returns(score_set)
    assert_same score_set, result_set.score_set

    match_set = stub('match set')
    Linkage::MatchSets::CSV.expects(:new).with({:dir => 'foo'}).returns(match_set)
    assert_same match_set, result_set.match_set
  end

  test "directory argument" do
    result_set = Linkage::ResultSets::CSV.new('foo')

    score_set = stub('score set')
    Linkage::ScoreSets::CSV.expects(:new).with({:dir => 'foo'}).returns(score_set)
    assert_same score_set, result_set.score_set

    match_set = stub('match set')
    Linkage::MatchSets::CSV.expects(:new).with({:dir => 'foo'}).returns(match_set)
    assert_same match_set, result_set.match_set
  end

  test "registers itself" do
    assert_same Linkage::ResultSets::CSV, Linkage::ResultSet['csv']
  end
end
