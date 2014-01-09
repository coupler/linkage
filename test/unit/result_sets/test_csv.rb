require 'helper'
require 'tempfile'

class UnitTests::TestCSV < Test::Unit::TestCase
  test "add_score" do
    tempfile = Tempfile.new('linkage')
    tempfile.close
    result_set = Linkage::ResultSets::CSV.new(tempfile.path)
    result_set.primary_key_1 = :foo
    result_set.primary_key_2 = :bar

    comparator = stub('comparator')
    result_set.add_comparator(comparator)
    result_set.add_score(comparator, {:foo => 1}, {:bar => 2}, 1)
    result_set.close

    expected = "comparator,id_1,id_2,score\n1,1,2,1\n"
    assert_equal expected, File.read(tempfile.path)
  end

  test "registers itself" do
    assert_equal Linkage::ResultSets::CSV, Linkage::ResultSet['csv']
  end
end
