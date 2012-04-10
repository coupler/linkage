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
    field_1 = stub('field_1', :to_expr => :foo)
    field_2 = stub('field_2', :to_expr => :bar)
    dataset = stub('dataset', :field_set => {:foo => field_1, :bar => :field_2})
    c = Linkage::Configuration.new(dataset, dataset)
    c.configure do
      lhs[:foo].must == rhs[:bar]
    end
    assert_equal :cross, c.linkage_type
  end

  test "linkage_type is cross when there's different filters on both sides" do
    field = stub('field', :to_expr => :foo)
    dataset = stub('dataset')
    dataset.stubs(:field_set).returns({:foo => field})
    c = Linkage::Configuration.new(dataset, dataset)
    c.configure do
      lhs[:foo].must == 123
      rhs[:foo].must == 456
    end
    assert_equal :cross, c.linkage_type
  end

  test "linkage_type is self when there's identical static filters on each side" do
    field = stub('field', :to_expr => :foo)
    dataset = stub('dataset')
    dataset.stubs(:field_set).returns({:foo => field})
    c = Linkage::Configuration.new(dataset, dataset)
    exp_1 = stub('expectation', :kind => :filter)
    c.configure do
      lhs[:foo].must == 123
      rhs[:foo].must == 123
    end
    assert_equal :self, c.linkage_type
  end

  test "linkage_type is self when there's a two-field filter on one side" do
    field_1 = stub('field 1', :to_expr => :foo)
    field_2 = stub('field 2', :to_expr => :bar)
    dataset = stub('dataset')
    dataset.stubs(:field_set).returns({:foo => field_1, :bar => field_2})
    c = Linkage::Configuration.new(dataset, dataset)
    c.configure do
      lhs[:foo].must == lhs[:bar]
      lhs[:foo].must == rhs[:foo]
    end
    assert_equal :self, c.linkage_type
  end

  test "static expectation" do
    dataset_1 = stub('dataset')
    field = stub('field', :to_expr => :foo)
    dataset_1.stubs(:field_set).returns({:foo => field})
    dataset_2 = stub('dataset')
    c = Linkage::Configuration.new(dataset_1, dataset_2)
    c.configure do
      lhs[:foo].must == 123
    end
    dataset_1.expects(:filter).with({:foo => 123}).returns(dataset_1)
    c.expectations[0].apply_to(dataset_1, :lhs)
  end

  test "complain if an invalid field is accessed" do
    dataset_1 = stub('dataset')
    field_1 = stub('field 1')
    dataset_1.stubs(:field_set).returns({:foo => field_1})

    dataset_2 = stub('dataset')
    field_2 = stub('field 2')
    dataset_2.stubs(:field_set).returns({:bar => field_2})

    c = Linkage::Configuration.new(dataset_1, dataset_2)
    assert_raises(ArgumentError) do
      c.configure do
        lhs[:foo].must == rhs[:non_existant_field]
      end
    end
  end

  operators = [:>, :<, :>=, :<=]
  operators.each do |operator|
    test "DSL #{operator} filter operator" do
      dataset_1 = stub('dataset 1')
      field_1 = stub('field 1', :to_expr => :foo)
      dataset_1.stubs(:field_set).returns({:foo => field_1})

      dataset_2 = stub('dataset 2')

      c = Linkage::Configuration.new(dataset_1, dataset_2)
      block = eval("Proc.new { lhs[:foo].must #{operator} rhs[:bar] }")
      c.configure do
        lhs[:foo].must.send(operator, 123)
      end
      expr = Sequel::SQL::BooleanExpression.new(operator, Sequel::SQL::Identifier.new(:foo), 123)
      dataset_1.expects(:filter).with(expr).returns(dataset_1)
      c.expectations[0].apply_to(dataset_1, :lhs)
    end
  end

  test "must_not expectation" do
    dataset_1 = stub('dataset 1')
    field_1 = stub('field 1', :to_expr => :foo)
    dataset_1.stubs(:field_set).returns({:foo => field_1})
    dataset_2 = stub('dataset 2')

    c = Linkage::Configuration.new(dataset_1, dataset_2)
    c.configure do
      lhs[:foo].must_not == 123
    end
    dataset_1.expects(:filter).with(~{:foo => 123}).returns(dataset_1)
    c.expectations[0].apply_to(dataset_1, :lhs)
  end

  test "dynamic database function" do
    dataset_1 = stub('dataset', :adapter_scheme => :sqlite)
    field_1 = stub('field 1')
    dataset_1.stubs(:field_set).returns({:foo => field_1})
    dataset_2 = stub('dataset', :adapter_scheme => :mysql2)
    field_2 = stub('field 2', :to_expr => :foo)
    dataset_2.stubs(:field_set).returns({:foo => field_2})

    func_expr = stub('function expression') do
      expects(:as).with(:trim_foo_foo).returns(self)
    end
    func = stub('function', :static? => false, :to_expr => func_expr)
    Linkage::Functions::Trim.expects(:new).with(field_1).returns(func)
    merged_field = stub('merged field', :name => :trim_foo_foo)
    func.expects(:merge).with(field_2).returns(merged_field)

    c = Linkage::Configuration.new(dataset_1, dataset_2)
    c.configure do
      trim(lhs[:foo]).must == rhs[:foo]
    end
    dataset_1.expects(:match).with(func_expr).returns(dataset_1)
    c.expectations[0].apply_to(dataset_1, :lhs)

    dataset_2.expects(:match).with(:foo.as(:trim_foo_foo)).returns(dataset_2)
    c.expectations[0].apply_to(dataset_2, :rhs)
  end

  test "static database function" do
    dataset_1 = stub('dataset', :adapter_scheme => :sqlite)
    field_1 = stub('field 1', :to_expr => :foo)
    dataset_1.stubs(:field_set).returns({:foo => field_1})
    dataset_2 = stub('dataset', :adapter_scheme => :mysql)
    field_2 = stub('field 2')
    dataset_2.stubs(:field_set).returns({:foo => field_2})

    func_expr = stub('function expression')
    func = stub('function', :static? => true, :to_expr => func_expr)
    Linkage::Functions::Trim.expects(:new).with("foo").returns(func)

    c = Linkage::Configuration.new(dataset_1, dataset_2)
    c.configure do
      lhs[:foo].must == trim("foo")
    end
    dataset_1.expects(:filter).with({:foo => func_expr}).returns(dataset_1)
    c.expectations[0].apply_to(dataset_1, :lhs)
  end

  test "save_results_in" do
    dataset_1 = stub('dataset')
    dataset_2 = stub('dataset')
    c = Linkage::Configuration.new(dataset_1, dataset_2)
    c.configure do
      save_results_in("mysql://localhost/results", {:foo => 'bar'})
    end
    assert_equal "mysql://localhost/results", c.results_uri
    assert_equal({:foo => 'bar'}, c.results_uri_options)
  end

  test "result_set" do
    dataset_1 = stub('dataset')
    dataset_2 = stub('dataset')
    c = Linkage::Configuration.new(dataset_1, dataset_2)

    result_set = stub('result set')
    Linkage::ResultSet.expects(:new).with(c).returns(result_set)
    assert_equal result_set, c.result_set
  end

  test "case insensitive field names" do
    field_1 = stub('field_1', :to_expr => :foo)
    field_2 = stub('field_2', :to_expr => :bar)
    field_set = {:foo => field_1, :bar => :field_2}
    field_set.expects(:has_key?).with(:Foo).returns(true)
    field_set.expects(:has_key?).with(:baR).returns(true)
    dataset = stub('dataset', :field_set => field_set)
    c = Linkage::Configuration.new(dataset, dataset)
    assert_nothing_raised do
      c.configure do
        lhs[:Foo].must == rhs[:baR]
      end
    end
  end
end
