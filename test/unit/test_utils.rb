require 'helper'

class UnitTests::TestUtils < Test::Unit::TestCase
  include Linkage::Utils

  test "merge two identical primary keys" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil}
    expected = {:type => Integer, :opts => {}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge two boolean fields" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"boolean", :type=>:boolean, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"boolean", :type=>:boolean, :ruby_default=>nil}
    expected = {:type => TrueClass, :opts => {}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge a boolean field and an integer field" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"integer", :type=>:integer, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"boolean", :type=>:boolean, :ruby_default=>nil}
    expected = {:type => Integer, :opts => {}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge a boolean field and a bignum field" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"bigint", :type=>:bigint, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"boolean", :type=>:boolean, :ruby_default=>nil}
    expected = {:type => Bignum, :opts => {}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge a boolean field and a float field" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"float", :type=>:float, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"boolean", :type=>:boolean, :ruby_default=>nil}
    expected = {:type => Float, :opts => {}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge a boolean field and a decimal field" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal", :type=>:decimal, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"boolean", :type=>:boolean, :ruby_default=>nil}
    expected = {:type => BigDecimal, :opts => {}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge a boolean field and a decimal field with size" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal(10,2)", :type=>:decimal, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"boolean", :type=>:boolean, :ruby_default=>nil}
    expected = {:type => BigDecimal, :opts => {:size => [10, 2]}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge a boolean field and a string field" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(10)", :type=>:string, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"boolean", :type=>:boolean, :ruby_default=>nil}
    expected = {:type => String, :opts => {:size => 10}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge a boolean field and a text field" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"text", :type=>:text, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"boolean", :type=>:boolean, :ruby_default=>nil}
    expected = {:type => String, :opts => {:text => true}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge a boolean field and a fixed string field" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"char(10)", :type=>:string, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"boolean", :type=>:boolean, :ruby_default=>nil}
    expected = {:type => String, :opts => {:size => 10, :fixed => true}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge two integer fields" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"integer", :type=>:integer, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"integer", :type=>:integer, :ruby_default=>nil}
    expected = {:type => Integer, :opts => {}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge an integer field and a bignum field" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"bigint", :type=>:bigint, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"integer", :type=>:integer, :ruby_default=>nil}
    expected = {:type => Bignum, :opts => {}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge an integer field and a float field" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"float", :type=>:float, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"integer", :type=>:integer, :ruby_default=>nil}
    expected = {:type => Float, :opts => {}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge an integer field and a decimal field" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal", :type=>:decimal, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"integer", :type=>:integer, :ruby_default=>nil}
    expected = {:type => BigDecimal, :opts => {}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge an integer field and a decimal field with size" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal(10,2)", :type=>:decimal, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"integer", :type=>:integer, :ruby_default=>nil}
    expected = {:type => BigDecimal, :opts => {:size => [10, 2]}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge an integer field and a string field" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(10)", :type=>:string, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"integer", :type=>:integer, :ruby_default=>nil}
    expected = {:type => String, :opts => {:size => 10}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge an integer field and a text field" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"text", :type=>:text, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"integer", :type=>:integer, :ruby_default=>nil}
    expected = {:type => String, :opts => {:text => true}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge an integer field and a fixed string field" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"char(10)", :type=>:string, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"integer", :type=>:integer, :ruby_default=>nil}
    expected = {:type => String, :opts => {:size => 10, :fixed => true}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge two bignum fields" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"bigint", :type=>:bigint, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"bigint", :type=>:bigint, :ruby_default=>nil}
    expected = {:type => Bignum, :opts => {}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge an bignum field and a decimal field" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal", :type=>:decimal, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"bigint", :type=>:bigint, :ruby_default=>nil}
    expected = {:type => BigDecimal, :opts => {}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge an bignum field and a decimal field with size" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal(10,2)", :type=>:decimal, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"bigint", :type=>:bigint, :ruby_default=>nil}
    expected = {:type => BigDecimal, :opts => {:size => [10, 2]}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge an bignum field and a string field" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(10)", :type=>:string, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"bigint", :type=>:bigint, :ruby_default=>nil}
    expected = {:type => String, :opts => {:size => 10}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge an bignum field and a text field" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"text", :type=>:text, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"bigint", :type=>:bigint, :ruby_default=>nil}
    expected = {:type => String, :opts => {:text => true}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge an bignum field and a fixed string field" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"char(10)", :type=>:string, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"bigint", :type=>:bigint, :ruby_default=>nil}
    expected = {:type => String, :opts => {:size => 10, :fixed => true}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge two float fields" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"float", :type=>:float, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"float", :type=>:float, :ruby_default=>nil}
    expected = {:type => Float, :opts => {}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge a float field and a bignum field" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"bigint", :type=>:bigint, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"float", :type=>:float, :ruby_default=>nil}
    expected = {:type => BigDecimal, :opts => {}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge a float field and a decimal field" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal", :type=>:decimal, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"float", :type=>:float, :ruby_default=>nil}
    expected = {:type => BigDecimal, :opts => {}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge a float field and a decimal field with size" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal(10,2)", :type=>:decimal, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"float", :type=>:float, :ruby_default=>nil}
    expected = {:type => BigDecimal, :opts => {:size => [10, 2]}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge a float field and a string field" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(10)", :type=>:string, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"float", :type=>:float, :ruby_default=>nil}
    expected = {:type => String, :opts => {:size => 10}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge a float field and a text field" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"text", :type=>:text, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"float", :type=>:float, :ruby_default=>nil}
    expected = {:type => String, :opts => {:text => true}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge a float field and a fixed string field" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"char(10)", :type=>:string, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"float", :type=>:float, :ruby_default=>nil}
    expected = {:type => String, :opts => {:size => 10, :fixed => true}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge two decimal fields" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal", :type=>:decimal, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal", :type=>:decimal, :ruby_default=>nil}
    expected = {:type => BigDecimal, :opts => {}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge two decimal fields, one with size" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal(10,2)", :type=>:decimal, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal", :type=>:decimal, :ruby_default=>nil}
    expected = {:type => BigDecimal, :opts => {:size => [10, 2]}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge two decimal fields, both with size" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal(10,2)", :type=>:decimal, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal(12,1)", :type=>:decimal, :ruby_default=>nil}
    expected = {:type => BigDecimal, :opts => {:size => [12, 2]}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge two decimal fields, both with size, one without scale" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal(10)", :type=>:decimal, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal(12,1)", :type=>:decimal, :ruby_default=>nil}
    expected = {:type => BigDecimal, :opts => {:size => [12, 1]}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge a decimal field and a string field" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(10)", :type=>:string, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal", :type=>:decimal, :ruby_default=>nil}
    expected = {:type => String, :opts => {:size => 10}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge a decimal field with size and a string field" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(10)", :type=>:string, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal(12,2)", :type=>:decimal, :ruby_default=>nil}
    expected = {:type => String, :opts => {:size => 13}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge a decimal field and a text field" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"text", :type=>:text, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal", :type=>:decimal, :ruby_default=>nil}
    expected = {:type => String, :opts => {:text => true}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge a decimal field with size and a text field" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"text", :type=>:text, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal(12,2)", :type=>:decimal, :ruby_default=>nil}
    expected = {:type => String, :opts => {:text => true}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge a decimal field and a fixed string field" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"char(10)", :type=>:string, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"decimal", :type=>:decimal, :ruby_default=>nil}
    expected = {:type => String, :opts => {:size => 10, :fixed => true}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge two string fields" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(20)", :type=>:string, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(20)", :type=>:string, :ruby_default=>nil}
    expected = {:type => String, :opts => {:size => 20}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end

  test "merge two string fields with different sizes" do
    field_1 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(15)", :type=>:string, :ruby_default=>nil}
    field_2 = {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(20)", :type=>:string, :ruby_default=>nil}
    expected = {:type => String, :opts => {:size => 20}}
    assert_equal(expected, merge_fields(field_1, field_2))
    assert_equal(expected, merge_fields(field_2, field_1))
  end
end
