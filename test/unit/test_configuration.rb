require 'helper'

class UnitTests::TestConfiguration < Test::Unit::TestCase
  test "adding comparator with set arguments" do
    fields_1 = stub('fieldset 1')
    dataset_1 = stub('dataset 1', :field_set => fields_1)
    fields_2 = stub('fieldset 2')
    dataset_2 = stub('dataset 2', :field_set => fields_2)
    config = Linkage::Configuration.new(dataset_1, dataset_2)

    field_1 = stub('field 1')
    fields_1.expects(:[]).with(:foo).returns(field_1)
    field_2 = stub('field 2')
    fields_2.expects(:[]).with(:foo).returns(field_2)
    compare = stub('compare')
    Linkage::Comparators::Compare.expects(:new).with([field_1], [field_2], :equal_to).returns(compare)
    config.compare([:foo], [:foo], :equal_to)
    assert_equal compare, config.comparators[0]
  end

  test "adding comparator with scalar arguments" do
    fields_1 = stub('fieldset 1')
    dataset_1 = stub('dataset 1', :field_set => fields_1)
    fields_2 = stub('fieldset 2')
    dataset_2 = stub('dataset 2', :field_set => fields_2)
    config = Linkage::Configuration.new(dataset_1, dataset_2)

    field_1 = stub('field 1')
    fields_1.expects(:[]).with(:foo).returns(field_1)
    field_2 = stub('field 2')
    fields_2.expects(:[]).with(:foo).returns(field_2)
    within = stub('within')
    Linkage::Comparators::Within.expects(:new).with(field_1, field_2, 5).returns(within)
    config.within(:foo, :foo, 5)
    assert_equal within, config.comparators[0]
  end
end
