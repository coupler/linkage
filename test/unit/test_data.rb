require 'helper'

class UnitTests::TestData < Test::Unit::TestCase
  class DataSubclass < Linkage::Data
    attr_reader :ruby_type, :dataset
    def initialize(name, ruby_type, dataset = nil)
      super(name)
      @ruby_type = ruby_type
      @dataset = dataset
    end
  end

  def new_data(name, ruby_type, dataset = nil, klass = DataSubclass)
    klass.new(name, ruby_type, dataset)
  end

  test "ruby_type raises NotImplementedError" do
    d = Linkage::Data.new(:foo)
    assert_raises(NotImplementedError) { d.ruby_type }
  end

  test "to_expr raises NotImplementedError" do
    d = Linkage::Data.new(:foo)
    assert_raises(NotImplementedError) { d.to_expr }
  end

  test "merge two identical fields" do
    data_1 = new_data(:id, {:type =>Integer})
    data_2 = new_data(:id, {:type =>Integer})
    expected_type = {:type => Integer}

    result_data = data_1.merge(data_2)
    assert_equal(:id, result_data.name)
    assert_equal(expected_type, result_data.ruby_type)

    result_data = data_2.merge(data_1)
    assert_equal(:id, result_data.name)
    assert_equal(expected_type, result_data.ruby_type)
  end

  test "merge fields with different names" do
    data_1 = new_data(:foo, {:type => Integer})
    data_2 = new_data(:bar, {:type => Integer})

    result_data = data_1.merge(data_2)
    assert_equal(:foo_bar, result_data.name)
    result_data = data_2.merge(data_1)
    assert_equal(:bar_foo, result_data.name)
  end

  test "merge two boolean fields" do
    data_1 = new_data(:foo, {:type => TrueClass})
    data_2 = new_data(:foo, {:type => TrueClass})
    expected_type = {:type => TrueClass}

    result_data = data_1.merge(data_2)
    assert_equal(:foo, result_data.name)
    assert_equal(expected_type, result_data.ruby_type)

    result_data = data_2.merge(data_1)
    assert_equal(:foo, result_data.name)
    assert_equal(expected_type, result_data.ruby_type)
  end

  test "merge a boolean field and an integer field" do
    data_1 = new_data(:foo, {:type => Integer})
    data_2 = new_data(:foo, {:type => TrueClass})
    expected_type = {:type => Integer}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge a boolean field and a bignum field" do
    data_1 = new_data(:foo, {:type => Bignum})
    data_2 = new_data(:foo, {:type => TrueClass})
    expected_type = {:type => Bignum}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge a boolean field and a float field" do
    data_1 = new_data(:foo, {:type => Float})
    data_2 = new_data(:foo, {:type => TrueClass})
    expected_type = {:type => Float}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge a boolean field and a decimal field" do
    data_1 = new_data(:foo, {:type => BigDecimal})
    data_2 = new_data(:foo, {:type => TrueClass})
    expected_type = {:type => BigDecimal}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge a boolean field and a decimal field with size" do
    data_1 = new_data(:foo, {:type => BigDecimal, :opts => {:size => [10, 2]}})
    data_2 = new_data(:foo, {:type => TrueClass})
    expected_type = {:type => BigDecimal, :opts => {:size => [10, 2]}}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge a boolean field and a string field" do
    data_1 = new_data(:foo, {:type => String, :opts => {:size => 10}})
    data_2 = new_data(:foo, {:type => TrueClass})
    expected_type = {:type => String, :opts => {:size => 10}}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge a boolean field and a text field" do
    data_1 = new_data(:foo, {:type => String, :opts => {:text => true}})
    data_2 = new_data(:foo, {:type => TrueClass})
    expected_type = {:type => String, :opts => {:text => true}}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge a boolean field and a fixed string field" do
    data_1 = new_data(:foo, {:type => String, :opts => {:size => 10, :fixed => true}})
    data_2 = new_data(:foo, {:type => TrueClass})
    expected_type = {:type => String, :opts => {:size => 10, :fixed => true}}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge two integer fields" do
    data_1 = new_data(:foo, {:type => Integer})
    data_2 = new_data(:foo, {:type => Integer})
    expected_type = {:type => Integer}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge an integer field and a bignum field" do
    data_1 = new_data(:foo, {:type => Bignum})
    data_2 = new_data(:foo, {:type => Integer})
    expected_type = {:type => Bignum}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge an integer field and a float field" do
    data_1 = new_data(:foo, {:type => Float})
    data_2 = new_data(:foo, {:type => Integer})
    expected_type = {:type => Float}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge an integer field and a decimal field" do
    data_1 = new_data(:foo, {:type => BigDecimal})
    data_2 = new_data(:foo, {:type => Integer})
    expected_type = {:type => BigDecimal}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge an integer field and a decimal field with size" do
    data_1 = new_data(:foo, {:type => BigDecimal, :opts => {:size => [10, 2]}})
    data_2 = new_data(:foo, {:type => Integer})
    expected_type = {:type => BigDecimal, :opts => {:size => [10, 2]}}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge an integer field and a string field" do
    data_1 = new_data(:foo, {:type => String, :opts => {:size => 10}})
    data_2 = new_data(:foo, {:type => Integer})
    expected_type = {:type => String, :opts => {:size => 10}}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge an integer field and a text field" do
    data_1 = new_data(:foo, {:type => String, :opts => {:text => true}})
    data_2 = new_data(:foo, {:type => Integer})
    expected_type = {:type => String, :opts => {:text => true}}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge an integer field and a fixed string field" do
    data_1 = new_data(:foo, {:type => String, :opts => {:size => 10, :fixed => true}})
    data_2 = new_data(:foo, {:type => Integer})
    expected_type = {:type => String, :opts => {:size => 10, :fixed => true}}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge two bignum fields" do
    data_1 = new_data(:foo, {:type => Bignum})
    data_2 = new_data(:foo, {:type => Bignum})
    expected_type = {:type => Bignum}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge an bignum field and a decimal field" do
    data_1 = new_data(:foo, {:type => BigDecimal})
    data_2 = new_data(:foo, {:type => Bignum})
    expected_type = {:type => BigDecimal}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge an bignum field and a decimal field with size" do
    data_1 = new_data(:foo, {:type => BigDecimal, :opts => {:size => [10, 2]}})
    data_2 = new_data(:foo, {:type => Bignum})
    expected_type = {:type => BigDecimal, :opts => {:size => [10, 2]}}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge an bignum field and a string field" do
    data_1 = new_data(:foo, {:type => String, :opts => {:size => 10}})
    data_2 = new_data(:foo, {:type => Bignum})
    expected_type = {:type => String, :opts => {:size => 10}}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge an bignum field and a text field" do
    data_1 = new_data(:foo, {:type => String, :opts => {:text => true}})
    data_2 = new_data(:foo, {:type => Bignum})
    expected_type = {:type => String, :opts => {:text => true}}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge an bignum field and a fixed string field" do
    data_1 = new_data(:foo, {:type => String, :opts => {:size => 10, :fixed => true}})
    data_2 = new_data(:foo, {:type => Bignum})
    expected_type = {:type => String, :opts => {:size => 10, :fixed => true}}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge two float fields" do
    data_1 = new_data(:foo, {:type => Float})
    data_2 = new_data(:foo, {:type => Float})
    expected_type = {:type => Float}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge a float field and a bignum field" do
    data_1 = new_data(:foo, {:type => Bignum})
    data_2 = new_data(:foo, {:type => Float})
    expected_type = {:type => BigDecimal}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge a float field and a decimal field" do
    data_1 = new_data(:foo, {:type => BigDecimal})
    data_2 = new_data(:foo, {:type => Float})
    expected_type = {:type => BigDecimal}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge a float field and a decimal field with size" do
    data_1 = new_data(:foo, {:type => BigDecimal, :opts => {:size => [10, 2]}})
    data_2 = new_data(:foo, {:type => Float})
    expected_type = {:type => BigDecimal, :opts => {:size => [10, 2]}}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge a float field and a string field" do
    data_1 = new_data(:foo, {:type => String, :opts => {:size => 10}})
    data_2 = new_data(:foo, {:type => Float})
    expected_type = {:type => String, :opts => {:size => 10}}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge a float field and a text field" do
    data_1 = new_data(:foo, {:type => String, :opts => {:text => true}})
    data_2 = new_data(:foo, {:type => Float})
    expected_type = {:type => String, :opts => {:text => true}}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge a float field and a fixed string field" do
    data_1 = new_data(:foo, {:type => String, :opts => {:size => 10, :fixed => true}})
    data_2 = new_data(:foo, {:type => Float})
    expected_type = {:type => String, :opts => {:size => 10, :fixed => true}}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge two decimal fields" do
    data_1 = new_data(:foo, {:type => BigDecimal})
    data_2 = new_data(:foo, {:type => BigDecimal})
    expected_type = {:type => BigDecimal}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge two decimal fields, one with size" do
    data_1 = new_data(:foo, {:type => BigDecimal, :opts => {:size => [10, 2]}})
    data_2 = new_data(:foo, {:type => BigDecimal})
    expected_type = {:type => BigDecimal, :opts => {:size => [10, 2]}}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge two decimal fields, both with size" do
    data_1 = new_data(:foo, {:type => BigDecimal, :opts => {:size => [10, 2]}})
    data_2 = new_data(:foo, {:type => BigDecimal, :opts => {:size => [12, 1]}})
    expected_type = {:type => BigDecimal, :opts => {:size => [12, 2]}}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge two decimal fields, both with size, one without scale" do
    data_1 = new_data(:foo, {:type => BigDecimal, :opts => {:size => [10]}})
    data_2 = new_data(:foo, {:type => BigDecimal, :opts => {:size => [12, 1]}})
    expected_type = {:type => BigDecimal, :opts => {:size => [12, 1]}}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge a decimal field and a string field" do
    data_1 = new_data(:foo, {:type => String, :opts => {:size => 10}})
    data_2 = new_data(:foo, {:type => BigDecimal})
    expected_type = {:type => String, :opts => {:size => 10}}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge a decimal field with size and a string field" do
    data_1 = new_data(:foo, {:type => String, :opts => {:size => 10}})
    data_2 = new_data(:foo, {:type => BigDecimal, :opts => {:size => [12, 2]}})
    expected_type = {:type => String, :opts => {:size => 13}}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge a decimal field and a text field" do
    data_1 = new_data(:foo, {:type => String, :opts => {:text => true}})
    data_2 = new_data(:foo, {:type => BigDecimal})
    expected_type = {:type => String, :opts => {:text => true}}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge a decimal field with size and a text field" do
    data_1 = new_data(:foo, {:type => String, :opts => {:text => true}})
    data_2 = new_data(:foo, {:type => BigDecimal, :opts => {:size => [12, 2]}})
    expected_type = {:type => String, :opts => {:text => true}}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge a decimal field and a fixed string field" do
    data_1 = new_data(:foo, {:type => String, :opts => {:size => 10, :fixed => true}})
    data_2 = new_data(:foo, {:type => BigDecimal})
    expected_type = {:type => String, :opts => {:size => 10, :fixed => true}}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge two string fields" do
    data_1 = new_data(:foo, {:type => String, :opts => {:size => 20}})
    data_2 = new_data(:foo, {:type => String, :opts => {:size => 20}})
    expected_type = {:type => String, :opts => {:size => 20}}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge two string fields with different sizes" do
    data_1 = new_data(:foo, {:type => String, :opts => {:size => 15}})
    data_2 = new_data(:foo, {:type => String, :opts => {:size => 20}})
    expected_type = {:type => String, :opts => {:size => 20}}
    assert_equal(expected_type, data_1.merge(data_2).ruby_type)
    assert_equal(expected_type, data_2.merge(data_1).ruby_type)
  end

  test "merge two fields and specify name" do
    data_1 = new_data(:id, {:type => Integer})
    data_2 = new_data(:id, {:type => Integer})

    result_data = data_1.merge(data_2, 'foo')
    assert_equal :foo, result_data.name

    result_data = data_2.merge(data_1, 'foo')
    assert_equal :foo, result_data.name
  end
end
