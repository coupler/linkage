require File.expand_path("../../test_match_sets", __FILE__)

class UnitTests::TestMatchSets::TestCSV < Test::Unit::TestCase
  test "open_for_writing" do
    match_set = Linkage::MatchSets::CSV.new('foo.csv')
    csv = stub('csv')
    CSV.expects(:open).with('foo.csv', 'wb').returns(csv)
    csv.expects(:<<).with(%w{id_1 id_2 score})
    match_set.open_for_writing
  end

  test "open_for_writing when already open" do
    match_set = Linkage::MatchSets::CSV.new('foo.csv')
    csv = stub('csv')
    CSV.expects(:open).once.with('foo.csv', 'wb').returns(csv)
    csv.expects(:<<).once.with(%w{id_1 id_2 score})
    match_set.open_for_writing
    match_set.open_for_writing
  end

  test "add_match when unopened raises exception" do
    match_set = Linkage::MatchSets::CSV.new('foo.csv')
    assert_raises { match_set.add_match(1, 2, 1) }
  end

  test "add_match" do
    tempfile = Tempfile.new('linkage')
    tempfile.close
    match_set = Linkage::MatchSets::CSV.new(tempfile.path)
    match_set.open_for_writing
    match_set.add_match(1, 2, 1)
    match_set.close

    expected = "id_1,id_2,score\n1,2,1\n"
    assert_equal expected, File.read(tempfile.path)
  end

  test "registers itself" do
    assert_equal Linkage::MatchSets::CSV, Linkage::MatchSet['csv']
  end
end
