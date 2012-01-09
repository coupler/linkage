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
    field = stub_field('field')
    dataset = stub('dataset', :set_new_id => nil)
    dataset.stubs(:fields).returns({:foo => field})
    c = Linkage::Configuration.new(dataset, dataset)
    exp_1 = stub('expectation', :kind => :filter)
    Linkage::MustExpectation.expects(:new).with(:==, field, 123, nil).returns(exp_1)
    exp_2 = stub('expectation', :kind => :filter)
    Linkage::MustExpectation.expects(:new).with(:==, field, 456, nil).returns(exp_2)
    c.send(:instance_eval) do
      lhs[:foo].must == 123
      rhs[:foo].must == 456
    end
    assert_equal :cross, c.linkage_type
  end

  test "linkage_type is self when there's identical static filters on each side" do
    field = stub_field('field')
    dataset = stub('dataset', :set_new_id => nil)
    dataset.stubs(:fields).returns({:foo => field})
    c = Linkage::Configuration.new(dataset, dataset)
    exp_1 = stub('expectation', :kind => :filter)
    Linkage::MustExpectation.expects(:new).twice.with(:==, field, 123, nil).returns(exp_1)
    c.send(:instance_eval) do
      lhs[:foo].must == 123
      rhs[:foo].must == 123
    end
    assert_equal :self, c.linkage_type
  end

  test "linkage_type is self when there's a two-field filter on one side" do
    field_1 = stub_field('field 1')
    field_2 = stub_field('field 2')
    dataset = stub('dataset', :set_new_id => nil)
    dataset.stubs(:fields).returns({:foo => field_1, :bar => field_2})
    c = Linkage::Configuration.new(dataset, dataset)
    exp_1 = stub('expectation', :kind => :filter)
    Linkage::MustExpectation.expects(:new).with(:==, field_1, field_2, :filter).returns(exp_1)
    exp_2 = stub('expectation', :kind => :self)
    Linkage::MustExpectation.expects(:new).with(:==, field_1, field_1, nil).returns(exp_2)
    c.send(:instance_eval) do
      lhs[:foo].must == lhs[:bar]
      lhs[:foo].must == rhs[:foo]
    end
    assert_equal :self, c.linkage_type
  end

  test "static expectation" do
    dataset_1 = stub('dataset')
    field = stub_field('field')
    dataset_1.stubs(:fields).returns({:foo => field})
    dataset_2 = stub('dataset')
    c = Linkage::Configuration.new(dataset_1, dataset_2)
    Linkage::MustExpectation.expects(:new).with(:==, field, 123, nil)
    c.send(:instance_eval) do
      lhs[:foo].must == 123
    end
  end

  ## Maybe in the future
  #test "static expectation, flopped" do
    #dataset_1 = stub('dataset')
    #field = stub_field('field')
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

  operators = [:>, :<, :>=, :<=]
  operators << :'!='  if current_ruby_version >= ruby19
  operators.each do |operator|
    test "DSL #{operator} filter operator" do
      dataset_1 = stub('dataset 1')
      field_1 = stub_field('field 1')
      dataset_1.stubs(:fields).returns({:foo => field_1})

      dataset_2 = stub('dataset 2')
      field_2 = stub_field('field 2')
      dataset_2.stubs(:fields).returns({:bar => field_2})

      c = Linkage::Configuration.new(dataset_1, dataset_2)
      Linkage::MustExpectation.expects(:new).with(operator, field_1, field_2, nil)
      block = eval("Proc.new { lhs[:foo].must #{operator} rhs[:bar] }")
      c.send(:instance_eval, &block)
    end
  end

  test "must_not expectation" do
    dataset_1 = stub('dataset 1')
    field_1 = stub_field('field 1')
    dataset_1.stubs(:fields).returns({:foo => field_1})
    dataset_2 = stub('dataset 2')

    c = Linkage::Configuration.new(dataset_1, dataset_2)
    Linkage::MustNotExpectation.expects(:new).with(:==, field_1, 123, nil)
    c.send(:instance_eval) do
      lhs[:foo].must_not == 123
    end
  end

  test "dynamic database function" do
    dataset_1 = stub('dataset')
    field_1 = stub_field('field 1')
    dataset_1.stubs(:fields).returns({:foo => field_1})
    dataset_2 = stub('dataset')
    field_2 = stub_field('field 2')
    dataset_2.stubs(:fields).returns({:foo => field_2})

    func = stub_function('function', :static? => false)
    Linkage::Functions::Trim.expects(:new).with(field_1).returns(func)

    c = Linkage::Configuration.new(dataset_1, dataset_2)
    Linkage::MustExpectation.expects(:new).with(:==, func, field_2, nil)
    c.send(:instance_eval) do
      trim(lhs[:foo]).must == rhs[:foo]
    end
  end

  test "static database function" do
    dataset_1 = stub('dataset')
    field_1 = stub_field('field 1')
    dataset_1.stubs(:fields).returns({:foo => field_1})
    dataset_2 = stub('dataset')
    field_2 = stub_field('field 2')
    dataset_2.stubs(:fields).returns({:foo => field_2})

    func = stub_function('function', :static? => true)
    Linkage::Functions::Trim.expects(:new).with("foo").returns(func)

    c = Linkage::Configuration.new(dataset_1, dataset_2)
    Linkage::MustExpectation.expects(:new).with(:==, field_1, func, :filter)
    c.send(:instance_eval) do
      lhs[:foo].must == trim("foo")
    end
  end

  test "save_results_in" do
    dataset_1 = stub('dataset')
    dataset_2 = stub('dataset')
    c = Linkage::Configuration.new(dataset_1, dataset_2)
    c.send(:instance_eval) do
      save_results_in("mysql://localhost/results", {:foo => 'bar'})
    end
    assert_equal "mysql://localhost/results", c.results_uri
    assert_equal({:foo => 'bar'}, c.results_uri_options)
  end
end
