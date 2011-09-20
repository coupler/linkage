require 'helper'

class UnitTests::TestConfiguration < Test::Unit::TestCase
  test "linkage_type is self when the two datasets are the same" do
    dataset = stub('dataset')
    c = Linkage::Configuration.new(dataset, dataset)
    assert_equal :self, c.linkage_type
  end

  test "linkage_type is dual when the two datasets are different" do
    dataset_1 = stub('dataset')
    dataset_2 = stub('dataset')
    c = Linkage::Configuration.new(dataset_1, dataset_2)
    assert_equal :dual, c.linkage_type
  end

  test "linkage_type is cross when there's a 'cross-join'" do
    dataset = mock('dataset', :set_new_id => nil)
    c = Linkage::Configuration.new(dataset, dataset)
    exp = stub('expectation', :kind => :cross)
    c.add_expectation(exp)
    assert_equal :cross, c.linkage_type
  end
end
