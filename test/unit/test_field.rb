require 'helper'

class UnitTests::TestField < Test::Unit::TestCase
  test "initialize with schema info" do
    schema = {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil}
    field = Linkage::Field.new(:id, schema)
    assert_equal :id, field.name
    assert_equal schema, field.schema
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
end
