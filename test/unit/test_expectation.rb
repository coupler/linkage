require 'helper'

class UnitTests::TestExpectation < Test::Unit::TestCase
  test "new must expectation with two fields" do
    Linkage::MustExpectation.new(:==, stub('field 1'), stub('field 2'))
  end

  test "get" do
    assert_equal Linkage::MustExpectation, Linkage::Expectation.get(:must)
  end
end
