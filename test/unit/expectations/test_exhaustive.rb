require 'helper'

class UnitTests::TestExhaustive < Test::Unit::TestCase
  test "initialize with comparator, threshold, and mode" do
    comparator = stub('comparator')
    exp = Linkage::Expectations::Exhaustive.new(comparator, 100, :min)
    assert_equal comparator, exp.comparator
    assert_equal 100, exp.threshold
    assert_equal :min, exp.mode
  end

  test "kind" do
    comparator = stub('comparator')
    exp = Linkage::Expectations::Exhaustive.new(comparator, 100, :min)
    assert_equal :exhaustive, exp.kind
  end
end
