require 'helper'

class UnitTests::TestConfiguration < Test::Unit::TestCase
  test "adding comparison" do
    dataset_1 = stub('dataset 1')
    dataset_2 = stub('dataset 2')
    config = Linkage::Configuration.new(dataset_1, dataset_2)

    compare = stub('compare')
    Linkage::Comparators::Compare.expects(:new).with([:foo], [:foo], :equal_to).returns(compare)
    config.compare([:foo], [:foo], :equal_to)
    assert_equal compare, config.comparisons[0]
  end
end
