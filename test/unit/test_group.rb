require 'helper'

class UnitTests::TestGroup < Test::Unit::TestCase
  test "matches?" do
    g = Linkage::Group.new(:test => 'test')
    assert g.matches?({:test => 'test'})
    assert !g.matches?({:foo => 'bar'})
  end

  test "add_record adds a record" do
    g = Linkage::Group.new(:test => 'test')
    g.add_record(123)
    assert_equal [123], g.records
  end

  test "count returns number of records" do
    g = Linkage::Group.new(:test => 'test')
    g.add_record(123)
    assert_equal 1, g.count
  end
end
