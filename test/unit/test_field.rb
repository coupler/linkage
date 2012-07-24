require 'helper'

class UnitTests::TestField < Test::Unit::TestCase
  test "subclass of data" do
    assert_equal Linkage::Data, Linkage::Field.superclass
  end

  test "initialize with schema info" do
    dataset = stub('dataset')
    schema = {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil}
    field = Linkage::Field.new(dataset, :id, schema)
    assert_equal :id, field.name
    assert_equal schema, field.schema
    assert_equal dataset, field.dataset
  end

  test "static? is always false" do
    dataset = stub('dataset')
    schema = {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil}
    field = Linkage::Field.new(dataset, :id, schema)
    assert !field.static?
  end

  test "ruby_type for integer" do
    dataset = stub('dataset')
    field = Linkage::Field.new(dataset, :id, {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    assert_equal({:type => Integer}, field.ruby_type)
  end

  test "primary_key? returns true if primary key" do
    dataset = stub('dataset')
    field_1 = Linkage::Field.new(dataset, :id, {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    assert field_1.primary_key?

    field_2 = Linkage::Field.new(dataset, :foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    assert !field_2.primary_key?
  end

  test "to_expr returns name" do
    dataset = stub('dataset')
    field = Linkage::Field.new(dataset, :id, {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    assert_equal :id, field.to_expr
  end

  test "to_expr ignores adapter argument" do
    dataset = stub('dataset')
    field = Linkage::Field.new(dataset, :id, {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    assert_equal :id, field.to_expr(:foo)
  end

  test "collation" do
    dataset = stub('dataset')
    field = Linkage::Field.new(dataset, :foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(255)", :type=>:string, :collate=>"latin1_general_cs", :ruby_default=>nil})
    assert_equal "latin1_general_cs", field.collation
  end

  test "initialize MergeField with ruby type" do
    info = {:type => Integer}
    field = Linkage::MergeField.new(:id, info)
    assert_equal :id, field.name
    assert_equal info, field.ruby_type
    assert_nil field.schema
    assert_nil field.dataset
  end
end
