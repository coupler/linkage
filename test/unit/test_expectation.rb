require 'helper'

class UnitTests::TestExpectation < Test::Unit::TestCase
  test "new must expectation with two fields" do
    Linkage::MustExpectation.new(:==, stub('field 1'), stub('field 2'))
  end

  test "get" do
    assert_equal Linkage::MustExpectation, Linkage::Expectation.get(:must)
  end

  test "kind when two fields from different datasets" do
    field_1 = mock('field 1')
    field_2 = mock('field 2')
    field_1.expects(:==).with(field_2).returns(false)
    exp = Linkage::MustExpectation.new(:==, field_1, field_2)
    assert_equal :dual, exp.kind
  end

  test "kind when two identical fields from the same dataset" do
    field_1 = mock('field 1')
    field_2 = mock('field 2')
    field_1.expects(:==).with(field_2).returns(true)
    exp = Linkage::MustExpectation.new(:==, field_1, field_2)
    assert_equal :self, exp.kind
  end
end
