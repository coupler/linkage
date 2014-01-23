require 'helper'
require 'tempfile'

class UnitTests::TestCSV < Test::Unit::TestCase
  test "open_for_writing" do
    result_set = Linkage::ResultSets::CSV.new('foo.csv')
    csv = stub('csv')
    CSV.expects(:open).with('foo.csv', 'wb').returns(csv)
    csv.expects(:<<).with(%w{comparator id_1 id_2 score})
    result_set.open_for_writing
  end

  test "open_for_writing when already open" do
    result_set = Linkage::ResultSets::CSV.new('foo.csv')
    csv = stub('csv')
    CSV.expects(:open).once.with('foo.csv', 'wb').returns(csv)
    csv.expects(:<<).once.with(%w{comparator id_1 id_2 score})
    result_set.open_for_writing
    result_set.open_for_writing
  end

  test "open_for_reading" do
    result_set = Linkage::ResultSets::CSV.new('foo.csv')
    csv = stub('csv')
    CSV.expects(:open).with('foo.csv', 'rb', {:headers => true}).returns(csv)
    result_set.open_for_reading
  end

  test "open_for_reading when already open" do
    result_set = Linkage::ResultSets::CSV.new('foo.csv')
    csv = stub('csv')
    CSV.expects(:open).once.with('foo.csv', 'rb', {:headers => true}).returns(csv)
    result_set.open_for_reading
    result_set.open_for_reading
  end

  test "open_for_writing when in read mode raises exception" do
    result_set = Linkage::ResultSets::CSV.new('foo.csv')
    csv = stub('csv')
    CSV.stubs(:open).returns(csv)
    result_set.open_for_reading
    assert_raises(RuntimeError) { result_set.open_for_writing }
  end

  test "open_for_reading when in write mode raises exception" do
    result_set = Linkage::ResultSets::CSV.new('foo.csv')
    csv = stub('csv', :<< => nil)
    CSV.stubs(:open).returns(csv)
    result_set.open_for_writing
    assert_raises(RuntimeError) { result_set.open_for_reading }
  end

  test "add_score when unopened raises exception" do
    result_set = Linkage::ResultSets::CSV.new('foo.csv')
    assert_raises { result_set.add_score(1, 1, 2, 1) }
  end

  test "add_score when in read mode raises exception" do
    result_set = Linkage::ResultSets::CSV.new('foo.csv')
    csv = stub('csv')
    CSV.stubs(:open).returns(csv)
    result_set.open_for_reading
    assert_raises { result_set.add_score(1, 1, 2, 1) }
  end

  test "add_score" do
    tempfile = Tempfile.new('linkage')
    tempfile.close
    result_set = Linkage::ResultSets::CSV.new(tempfile.path)
    result_set.open_for_writing
    result_set.add_score(1, 1, 2, 1)
    result_set.close

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
    EOF
    tempfile.close
    result_set = Linkage::ResultSets::CSV.new(tempfile.path)

    pairs = []
    result_set.each_pair { |*args| pairs << args }
    assert_equal 2, pairs.length

    pair_1 = pairs.detect { |pair| pair[0] == "1" && pair[1] == "2" }
    assert pair_1
    assert_equal [[1, 1], [2, 0]], pair_1[2]

    pair_2 = pairs.detect { |pair| pair[0] == "2" && pair[1] == "3" }
    assert pair_2
    assert_equal [[1, 1], [2, 1]], pair_2[2]
  end

  test "registers itself" do
    assert_equal Linkage::ResultSets::CSV, Linkage::ResultSet['csv']
  end
end
