require 'helper'

class UnitTests::TestConfiguration < Test::Unit::TestCase
  test "result_set" do
    dataset_1 = stub('dataset')
    dataset_2 = stub('dataset')
    c = Linkage::Configuration.new(dataset_1, dataset_2)

    result_set = stub('result set')
    Linkage::ResultSet.expects(:new).with(c).returns(result_set)
    assert_equal result_set, c.result_set
  end
end
