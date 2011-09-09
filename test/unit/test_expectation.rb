require 'helper'

class UnitTests::TestExpectation < Test::Unit::TestCase
  test "new must expectation with two fields" do
    Linkage::MustExpectation.new(:==, stub('field 1'), stub('field 2'))
  end

  test "get" do
    assert_equal Linkage::MustExpectation, Linkage::Expectation.get(:must)
  end

  test "kind when two fields from different datasets" do
    dataset_1 = mock('dataset 1')
    dataset_2 = mock('dataset 2')
    dataset_1.expects(:==).with(dataset_2).returns(false)
    field_1 = mock('field 1', :dataset => dataset_1)
    field_2 = mock('field 2', :dataset => dataset_2)
    exp = Linkage::MustExpectation.new(:==, field_1, field_2)
    assert_equal :join, exp.kind
  end
end
