require 'helper'

class UnitTests::TestField < Test::Unit::TestCase
  test "subclass of data" do
    assert_equal Linkage::Data, Linkage::Field.superclass
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

  test "static? is always false" do
    schema = {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil}
    field = Linkage::Field.new(:id, schema)
    assert !field.static?
  end

  test "ruby_type for integer" do
    field = Linkage::Field.new(:id, {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    assert_equal({:type => Integer}, field.ruby_type)
  end

  test "primary_key? returns true if primary key" do
    field_1 = Linkage::Field.new(:id, {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    assert field_1.primary_key?

    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    assert !field_2.primary_key?
  end

  test "to_expr returns name" do
    field = Linkage::Field.new(:id, {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    assert_equal :id, field.to_expr
  end

  test "to_expr ignores adapter argument" do
    field = Linkage::Field.new(:id, {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    assert_equal :id, field.to_expr(:foo)
  end

  test "collation" do
    field = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(255)", :type=>:string, :collate=>"latin1_general_cs", :ruby_default=>nil})
    assert_equal "latin1_general_cs", field.collation
  end
end
