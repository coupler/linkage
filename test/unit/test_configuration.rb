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

  test "linkage_type is cross when there's different filters on both sides" do
    pend
    dataset = mock('dataset', :set_new_id => nil)
    c = Linkage::Configuration.new(dataset, dataset)
    exp = stub('expectation', :kind => :filter)
    c.add_expectation(exp)
    assert_equal :cross, c.linkage_type
  end

  test "static expectation" do
    dataset_1 = stub('dataset')
    field = stub('field')
    dataset_1.stubs(:fields).returns({:foo => field})
    dataset_2 = stub('dataset')
    c = Linkage::Configuration.new(dataset_1, dataset_2)
    Linkage::MustExpectation.expects(:new).with(:==, field, 123)
    c.send(:instance_eval) do
      lhs[:foo].must == 123
    end
  end

  ## Maybe in the future
  #test "static expectation, flopped" do
    #dataset_1 = stub('dataset')
    #field = stub('field')
    #dataset_1.stubs(:fields).returns({:foo => field})
    #dataset_2 = stub('dataset')
    #c = Linkage::Configuration.new(dataset_1, dataset_2)
    #Linkage::MustExpectation.expects(:new).with(:==, 123, field)
    #c.send(:instance_eval) do
      #123.must == lhs[:foo]
    #end
  #end

  test "complain if an invalid field is accessed" do
    dataset_1 = stub('dataset')
    field_1 = stub_field('field 1')
    dataset_1.stubs(:fields).returns({:foo => field_1})

    dataset_2 = stub('dataset')
    field_2 = stub_field('field 2')
    dataset_2.stubs(:fields).returns({:bar => field_2})

    c = Linkage::Configuration.new(dataset_1, dataset_2)
    assert_raises(ArgumentError) do
      c.send(:instance_eval) do
        lhs[:foo].must == rhs[:non_existant_field]
      end
    end
  end

  [:>, :<, :>=, :<=, :'!='].each do |operator|
    test "DSL #{operator} filter operator" do
      dataset_1 = stub('dataset 1')
      field_1 = stub_field('field 1')
      dataset_1.stubs(:fields).returns({:foo => field_1})

      dataset_2 = stub('dataset 2')
      field_2 = stub_field('field 2')
      dataset_2.stubs(:fields).returns({:bar => field_2})

      c = Linkage::Configuration.new(dataset_1, dataset_2)
      Linkage::MustExpectation.expects(:new).with(operator, field_1, field_2)
      block = eval("Proc.new { lhs[:foo].must #{operator} rhs[:bar] }")
      c.send(:instance_eval, &block)
    end
  end
end
