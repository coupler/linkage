require File.expand_path("../../test_match_sets", __FILE__)

class UnitTests::TestMatchSets::TestCSV < Test::Unit::TestCase
  test "open_for_writing" do
    match_set = Linkage::MatchSets::CSV.new(:filename => 'foo.csv')
    expected_filename = File.expand_path('foo.csv')
    File.expects(:exist?).with(expected_filename).returns(false)
    csv = stub('csv')
    CSV.expects(:open).with(expected_filename, 'wb').returns(csv)
    csv.expects(:<<).with(%w{id_1 id_2 score})
    match_set.open_for_writing
  end

  test "open_for_writing with default options" do
    match_set = Linkage::MatchSets::CSV.new
    expected_filename = File.expand_path('matches.csv')
    File.expects(:exist?).with(expected_filename).returns(false)
    csv = stub('csv')
    CSV.expects(:open).with(expected_filename, 'wb').returns(csv)
    csv.expects(:<<).with(%w{id_1 id_2 score})
    match_set.open_for_writing
  end

  test "open_for_writing with directory option" do
    match_set = Linkage::MatchSets::CSV.new(:dir => 'foo')

    expected_dir = File.expand_path('foo')
    FileUtils.expects(:mkdir_p).with(expected_dir)
    expected_filename = File.join(expected_dir, 'matches.csv')
    File.expects(:exist?).with(expected_filename).returns(false)
    csv = stub('csv')
    CSV.expects(:open).with(expected_filename, 'wb').returns(csv)
    csv.expects(:<<).with(%w{id_1 id_2 score})
    match_set.open_for_writing
  end

  test "open_for_writing when already open" do
    match_set = Linkage::MatchSets::CSV.new(:filename => 'foo.csv')
    expected_filename = File.expand_path('foo.csv')
    File.expects(:exist?).once.with(expected_filename).returns(false)
    csv = stub('csv')
    CSV.expects(:open).once.with(expected_filename, 'wb').returns(csv)
    csv.expects(:<<).once.with(%w{id_1 id_2 score})
    match_set.open_for_writing
    match_set.open_for_writing
  end

  test "open_for_writing when file exists" do
    match_set = Linkage::MatchSets::CSV.new(:filename => 'foo.csv')
    expected_filename = File.expand_path('foo.csv')
    File.expects(:exist?).with(expected_filename).returns(true)
    assert_raises(Linkage::ExistsError) do
      match_set.open_for_writing
    end
  end

  test "open_for_writing when file exists and forcing overwrite" do
    match_set = Linkage::MatchSets::CSV.new(:filename => 'foo.csv', :overwrite => true)
    expected_filename = File.expand_path('foo.csv')
    File.stubs(:exist?).with(expected_filename).returns(true)
    assert_nothing_raised do
      csv = stub('csv')
      CSV.expects(:open).with(expected_filename, 'wb').returns(csv)
      csv.expects(:<<).with(%w{id_1 id_2 score})
      match_set.open_for_writing
    end
  end

  test "add_match when unopened raises exception" do
    match_set = Linkage::MatchSets::CSV.new(:filename => 'foo.csv')
    assert_raises { match_set.add_match(1, 2, 1) }
  end

  test "add_match" do
    tempfile = Tempfile.new('linkage')
    tempfile.close
    match_set = Linkage::MatchSets::CSV.new(:filename => tempfile.path, :overwrite => true)
    match_set.open_for_writing
    match_set.add_match(1, 2, 1)
    match_set.close

    expected = "id_1,id_2,score\n1,2,1\n"
    assert_equal expected, File.read(tempfile.path)
  end

  test "add_match removes extra decimals" do
    match_set = Linkage::MatchSets::CSV.new(:filename => 'foo.csv')
    expected_filename = File.expand_path('foo.csv')
    File.expects(:exist?).with(expected_filename).returns(false)
    csv = stub('csv')
    CSV.stubs(:open).with(expected_filename, 'wb').returns(csv)
    csv.stubs(:<<).with(%w{id_1 id_2 score})
    match_set.open_for_writing

    csv.expects(:<<).with do |(id_1, id_2, score)|
      id_1 == 1 && id_2 == 2 && score.equal?(1)
    end
    match_set.add_match(1, 2, 1.0)

    csv.expects(:<<).with do |(id_1, id_2, score)|
      id_1 == 1 && id_2 == 2 && score.equal?(0)
    end
    match_set.add_match(1, 2, 0.0)
  end

  test "registers itself" do
    assert_equal Linkage::MatchSets::CSV, Linkage::MatchSet['csv']
  end
end
