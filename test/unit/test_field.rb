require 'helper'

class UnitTests::TestField < Test::Unit::TestCase
  def new_field(name, schema, ruby_type, dataset = nil)
    f = Linkage::Field.new(name, schema, ruby_type)
    f.dataset = dataset || stub('dataset')
    f
  end

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
    dataset = stub('dataset 1', :id => 1)
    field = Linkage::Field.new(:id, {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    field.dataset = dataset
    assert field.belongs_to?(dataset)
  end

  test "belongs_to? dataset with same id" do
    dataset_1 = stub('dataset 1', :id => 1)
    dataset_2 = stub('dataset 2', :id => 1)
    field = Linkage::Field.new(:id, {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    field.dataset = dataset_1
    assert field.belongs_to?(dataset_2)
  end

  test "belongs_to? dataset with different id" do
    dataset_1 = stub('dataset 1', :id => 1)
    dataset_2 = stub('dataset 2', :id => 2)
    field = Linkage::Field.new(:id, {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    field.dataset = dataset_1
    assert !field.belongs_to?(dataset_2)
  end

  test "primary_key? returns true if primary key" do
    field_1 = Linkage::Field.new(:id, {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    assert field_1.primary_key?

    field_2 = Linkage::Field.new(:foo, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"integer", :type=>:integer, :ruby_default=>nil})
    assert !field_2.primary_key?
  end
end
