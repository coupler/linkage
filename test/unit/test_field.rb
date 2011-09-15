require 'helper'

class UnitTests::TestField < Test::Unit::TestCase
  def new_field(name, schema, ruby_type, dataset = nil)
    f = Linkage::Field.new(name, schema, ruby_type)
    f.dataset = dataset || stub('dataset')
    f
  end

  test "initialize with schema info" do
    schema = {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil}
    field = Linkage::Field.new(:id, schema)
    assert_equal :id, field.name
    assert_equal schema, field.schema
  end

  test "initialize with ruby type" do
    info = {:type => Integer}
    field = Linkage::Field.new(:id, nil, info)
    assert_equal :id, field.name
    assert_equal info, field.ruby_type
  end

  test "merge two identical fields" do
    field_1 = Linkage::Field.new(:id, {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:id, {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    expected_type = {:type => Integer}

    result_field = field_1.merge(field_2)
    assert_equal(:id, result_field.name)
    assert_equal(expected_type, result_field.ruby_type)

    result_field = field_2.merge(field_1)
    assert_equal(:id, result_field.name)
    assert_equal(expected_type, result_field.ruby_type)
  end

  test "merge fields with different names" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:bar, {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})

    result_field = field_1.merge(field_2)
    assert_equal(:foo_bar, result_field.name)
    result_field = field_2.merge(field_1)
    assert_equal(:bar_foo, result_field.name)
  end

  test "merge two boolean fields" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"boolean", :type=>:boolean, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"boolean", :type=>:boolean, :ruby_default=>nil})
    expected_type = {:type => TrueClass}

    result_field = field_1.merge(field_2)
    assert_equal(:foo, result_field.name)
    assert_equal(expected_type, result_field.ruby_type)

    result_field = field_2.merge(field_1)
    assert_equal(:foo, result_field.name)
    assert_equal(expected_type, result_field.ruby_type)
  end

  test "merge a boolean field and an integer field" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"boolean", :type=>:boolean, :ruby_default=>nil})
    expected_type = {:type => Integer}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge a boolean field and a bignum field" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"bigint", :type=>:bigint, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"boolean", :type=>:boolean, :ruby_default=>nil})
    expected_type = {:type => Bignum}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge a boolean field and a float field" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"float", :type=>:float, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"boolean", :type=>:boolean, :ruby_default=>nil})
    expected_type = {:type => Float}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge a boolean field and a decimal field" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal", :type=>:decimal, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"boolean", :type=>:boolean, :ruby_default=>nil})
    expected_type = {:type => BigDecimal}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge a boolean field and a decimal field with size" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal(10,2)", :type=>:decimal, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"boolean", :type=>:boolean, :ruby_default=>nil})
    expected_type = {:type => BigDecimal, :opts => {:size => [10, 2]}}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge a boolean field and a string field" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(10)", :type=>:string, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"boolean", :type=>:boolean, :ruby_default=>nil})
    expected_type = {:type => String, :opts => {:size => 10}}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge a boolean field and a text field" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"text", :type=>:text, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"boolean", :type=>:boolean, :ruby_default=>nil})
    expected_type = {:type => String, :opts => {:text => true}}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge a boolean field and a fixed string field" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"char(10)", :type=>:string, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"boolean", :type=>:boolean, :ruby_default=>nil})
    expected_type = {:type => String, :opts => {:size => 10, :fixed => true}}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge two integer fields" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    expected_type = {:type => Integer}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge an integer field and a bignum field" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"bigint", :type=>:bigint, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    expected_type = {:type => Bignum}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge an integer field and a float field" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"float", :type=>:float, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    expected_type = {:type => Float}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge an integer field and a decimal field" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal", :type=>:decimal, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    expected_type = {:type => BigDecimal}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge an integer field and a decimal field with size" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal(10,2)", :type=>:decimal, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    expected_type = {:type => BigDecimal, :opts => {:size => [10, 2]}}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge an integer field and a string field" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(10)", :type=>:string, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    expected_type = {:type => String, :opts => {:size => 10}}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge an integer field and a text field" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"text", :type=>:text, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    expected_type = {:type => String, :opts => {:text => true}}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge an integer field and a fixed string field" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"char(10)", :type=>:string, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    expected_type = {:type => String, :opts => {:size => 10, :fixed => true}}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge two bignum fields" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"bigint", :type=>:bigint, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"bigint", :type=>:bigint, :ruby_default=>nil})
    expected_type = {:type => Bignum}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge an bignum field and a decimal field" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal", :type=>:decimal, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"bigint", :type=>:bigint, :ruby_default=>nil})
    expected_type = {:type => BigDecimal}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge an bignum field and a decimal field with size" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal(10,2)", :type=>:decimal, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"bigint", :type=>:bigint, :ruby_default=>nil})
    expected_type = {:type => BigDecimal, :opts => {:size => [10, 2]}}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge an bignum field and a string field" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(10)", :type=>:string, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"bigint", :type=>:bigint, :ruby_default=>nil})
    expected_type = {:type => String, :opts => {:size => 10}}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge an bignum field and a text field" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"text", :type=>:text, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"bigint", :type=>:bigint, :ruby_default=>nil})
    expected_type = {:type => String, :opts => {:text => true}}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge an bignum field and a fixed string field" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"char(10)", :type=>:string, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"bigint", :type=>:bigint, :ruby_default=>nil})
    expected_type = {:type => String, :opts => {:size => 10, :fixed => true}}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge two float fields" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"float", :type=>:float, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"float", :type=>:float, :ruby_default=>nil})
    expected_type = {:type => Float}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge a float field and a bignum field" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"bigint", :type=>:bigint, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"float", :type=>:float, :ruby_default=>nil})
    expected_type = {:type => BigDecimal}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge a float field and a decimal field" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal", :type=>:decimal, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"float", :type=>:float, :ruby_default=>nil})
    expected_type = {:type => BigDecimal}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge a float field and a decimal field with size" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal(10,2)", :type=>:decimal, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"float", :type=>:float, :ruby_default=>nil})
    expected_type = {:type => BigDecimal, :opts => {:size => [10, 2]}}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge a float field and a string field" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(10)", :type=>:string, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"float", :type=>:float, :ruby_default=>nil})
    expected_type = {:type => String, :opts => {:size => 10}}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge a float field and a text field" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"text", :type=>:text, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"float", :type=>:float, :ruby_default=>nil})
    expected_type = {:type => String, :opts => {:text => true}}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge a float field and a fixed string field" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"char(10)", :type=>:string, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"float", :type=>:float, :ruby_default=>nil})
    expected_type = {:type => String, :opts => {:size => 10, :fixed => true}}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge two decimal fields" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal", :type=>:decimal, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal", :type=>:decimal, :ruby_default=>nil})
    expected_type = {:type => BigDecimal}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge two decimal fields, one with size" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal(10,2)", :type=>:decimal, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal", :type=>:decimal, :ruby_default=>nil})
    expected_type = {:type => BigDecimal, :opts => {:size => [10, 2]}}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge two decimal fields, both with size" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal(10,2)", :type=>:decimal, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal(12,1)", :type=>:decimal, :ruby_default=>nil})
    expected_type = {:type => BigDecimal, :opts => {:size => [12, 2]}}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge two decimal fields, both with size, one without scale" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal(10)", :type=>:decimal, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal(12,1)", :type=>:decimal, :ruby_default=>nil})
    expected_type = {:type => BigDecimal, :opts => {:size => [12, 1]}}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge a decimal field and a string field" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(10)", :type=>:string, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal", :type=>:decimal, :ruby_default=>nil})
    expected_type = {:type => String, :opts => {:size => 10}}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge a decimal field with size and a string field" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(10)", :type=>:string, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal(12,2)", :type=>:decimal, :ruby_default=>nil})
    expected_type = {:type => String, :opts => {:size => 13}}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge a decimal field and a text field" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"text", :type=>:text, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal", :type=>:decimal, :ruby_default=>nil})
    expected_type = {:type => String, :opts => {:text => true}}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge a decimal field with size and a text field" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"text", :type=>:text, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal(12,2)", :type=>:decimal, :ruby_default=>nil})
    expected_type = {:type => String, :opts => {:text => true}}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge a decimal field and a fixed string field" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"char(10)", :type=>:string, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal", :type=>:decimal, :ruby_default=>nil})
    expected_type = {:type => String, :opts => {:size => 10, :fixed => true}}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge two string fields" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(20)", :type=>:string, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(20)", :type=>:string, :ruby_default=>nil})
    expected_type = {:type => String, :opts => {:size => 20}}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge two string fields with different sizes" do
    field_1 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(15)", :type=>:string, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(20)", :type=>:string, :ruby_default=>nil})
    expected_type = {:type => String, :opts => {:size => 20}}
    assert_equal(expected_type, field_1.merge(field_2).ruby_type)
    assert_equal(expected_type, field_2.merge(field_1).ruby_type)
  end

  test "merge two fields and specify name" do
    field_1 = Linkage::Field.new(:id, {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    field_2 = Linkage::Field.new(:id, {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})

    result_field = field_1.merge(field_2, 'foo')
    assert_equal :foo, result_field.name

    result_field = field_2.merge(field_1, 'foo')
    assert_equal :foo, result_field.name
  end

  test "== returns true when fields have the same name and are from the same dataset" do
    dataset_1 = stub('dataset')
    field_1 = Linkage::Field.new(:id, {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    field_1.dataset = dataset_1
    dataset_2 = stub('dataset clone')
    field_2 = Linkage::Field.new(:id, {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    field_2.dataset = dataset_2

    dataset_1.expects(:==).with(dataset_2).returns(true)
    assert_equal field_1, field_2
  end

  test "== returns false when fields have the same name but are from different datasets" do
    dataset_1 = stub('dataset 1')
    field_1 = Linkage::Field.new(:id, {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    field_1.dataset = dataset_1
    dataset_2 = stub('dataset 2')
    field_2 = Linkage::Field.new(:id, {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    field_2.dataset = dataset_2

    dataset_1.expects(:==).with(dataset_2).returns(false)
    assert_not_equal field_1, field_2
  end

  test "belongs_to? dataset" do
    dataset = stub('dataset 1')
    field = Linkage::Field.new(:id, {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    field.dataset = dataset
    assert field.belongs_to?(dataset)
  end

  test "primary_key? returns true if primary key" do
    field_1 = Linkage::Field.new(:id, {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    assert field_1.primary_key?

    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    assert !field_2.primary_key?
  end
end
