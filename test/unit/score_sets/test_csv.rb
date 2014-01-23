require File.expand_path("../../test_score_sets", __FILE__)

class UnitTests::TestScoreSets::TestCSV < Test::Unit::TestCase
  test "open_for_writing" do
    score_set = Linkage::ScoreSets::CSV.new('foo.csv')
    csv = stub('csv')
    CSV.expects(:open).with('foo.csv', 'wb').returns(csv)
    csv.expects(:<<).with(%w{comparator id_1 id_2 score})
    score_set.open_for_writing
  end

  test "open_for_writing when already open" do
    score_set = Linkage::ScoreSets::CSV.new('foo.csv')
    csv = stub('csv')
    CSV.expects(:open).once.with('foo.csv', 'wb').returns(csv)
    csv.expects(:<<).once.with(%w{comparator id_1 id_2 score})
    score_set.open_for_writing
    score_set.open_for_writing
  end

  test "open_for_reading" do
    score_set = Linkage::ScoreSets::CSV.new('foo.csv')
    csv = stub('csv')
    CSV.expects(:open).with('foo.csv', 'rb', {:headers => true}).returns(csv)
    score_set.open_for_reading
  end

  test "open_for_reading when already open" do
    score_set = Linkage::ScoreSets::CSV.new('foo.csv')
    csv = stub('csv')
    CSV.expects(:open).once.with('foo.csv', 'rb', {:headers => true}).returns(csv)
    score_set.open_for_reading
    score_set.open_for_reading
  end

  test "open_for_writing when in read mode raises exception" do
    score_set = Linkage::ScoreSets::CSV.new('foo.csv')
    csv = stub('csv')
    CSV.stubs(:open).returns(csv)
    score_set.open_for_reading
    assert_raises(RuntimeError) { score_set.open_for_writing }
  end

  test "open_for_reading when in write mode raises exception" do
    score_set = Linkage::ScoreSets::CSV.new('foo.csv')
    csv = stub('csv', :<< => nil)
    CSV.stubs(:open).returns(csv)
    score_set.open_for_writing
    assert_raises(RuntimeError) { score_set.open_for_reading }
  end

  test "add_score when unopened raises exception" do
    score_set = Linkage::ScoreSets::CSV.new('foo.csv')
    assert_raises { score_set.add_score(1, 1, 2, 1) }
  end

  test "add_score when in read mode raises exception" do
    score_set = Linkage::ScoreSets::CSV.new('foo.csv')
    csv = stub('csv')
    CSV.stubs(:open).returns(csv)
    score_set.open_for_reading
    assert_raises { score_set.add_score(1, 1, 2, 1) }
  end

  test "add_score" do
    tempfile = Tempfile.new('linkage')
    tempfile.close
    score_set = Linkage::ScoreSets::CSV.new(tempfile.path)
    score_set.open_for_writing
    score_set.add_score(1, 1, 2, 1)
    score_set.close

    expected = "comparator,id_1,id_2,score\n1,1,2,1\n"
    assert_equal expected, File.read(tempfile.path)
  end

  test "each_pair" do
    tempfile = Tempfile.new('linkage')
    tempfile.write(<<-EOF.gsub(/^\s*/, ""))
      comparator,id_1,id_2,score
      1,1,2,1
      1,2,3,1
      2,1,2,0
      2,2,3,1
      2,3,4,1
      1,3,4,0
    EOF
    tempfile.close
    score_set = Linkage::ScoreSets::CSV.new(tempfile.path)

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
    assert_equal Linkage::ScoreSets::CSV, Linkage::ScoreSet['csv']
  end
end
