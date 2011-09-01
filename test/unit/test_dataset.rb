require 'helper'

class UnitTests::TestDataset < Test::Unit::TestCase
  def setup
    @database = stub("database")
    Sequel.stubs(:connect).returns(@database)
    @schema = [
      [:id, {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil}],
      [:first_name, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(255)", :type=>:string, :ruby_default=>nil}],
      [:last_name, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(255)", :type=>:string, :ruby_default=>nil}]
    ]
    @database.stubs(:schema).returns(@schema)
    @dataset = stub("dataset")
    @database.stubs(:[]).returns(@dataset)
    @field = stub("field", :dataset= => nil)
    Linkage::Field.stubs(:new).returns(@field)
  end

  test "initialize with uri and table name" do
    Sequel.expects(:connect).with("foo:/bar").returns(@database)
    @database.expects(:schema).with(:baz).returns(@schema)
    primary_key_field = mock(:dataset= => nil)
    Linkage::Field.expects(:new).with(*@schema[0]).returns(primary_key_field)
    Linkage::Field.expects(:new).with(*@schema[1]).returns(mock(:dataset= => nil))
    Linkage::Field.expects(:new).with(*@schema[2]).returns(mock(:dataset= => nil))
    @database.expects(:[]).with(:baz).returns(@dataset)

    ds = Linkage::Dataset.new("foo:/bar", "baz")
    assert_equal primary_key_field, ds.primary_key
  end

  test "link_with self makes a copy" do
    dataset = Linkage::Dataset.new("foo:/bar", "baz")

    dataset_clone = stub('dataset clone')
    dataset.expects(:clone).returns(dataset_clone)

    conf = stub('configuration')
    Linkage::Configuration.expects(:new).with(dataset, dataset_clone).returns(conf)
    conf.expects(:instance_eval)

    result = dataset.link_with(dataset) do
      lhs[:first_name].must == rhs[:first_name]
    end
    assert_equal conf, result
  end

  test "== compares uri and table name" do
    dataset_1 = Linkage::Dataset.new("foo:/bar", "baz")
    dataset_2 = Linkage::Dataset.new("foo:/bar", "baz")
    dataset_3 = Linkage::Dataset.new("foo:/qux", "corge")
    assert_equal dataset_1, dataset_2
    assert_not_equal dataset_1, dataset_3
  end

  test "dup" do
    dataset_1 = Linkage::Dataset.new("foo:/bar", "baz")

    ds = stub('new dataset')
    Linkage::Dataset.expects(:new).with('foo:/bar', :baz).returns(ds)
    dataset_2 = dataset_1.dup
    assert_equal ds, dataset_2
  end

  test "clone doesn't shallow copy fields" do
    field_1 = stub('field 1', :dataset= => nil)
    Linkage::Field.expects(:new).with(*@schema[0]).returns(field_1)
    field_2 = stub('field 2', :dataset= => nil)
    Linkage::Field.expects(:new).with(*@schema[1]).returns(field_2)
    field_3 = stub('field 3', :dataset= => nil)
    Linkage::Field.expects(:new).with(*@schema[2]).returns(field_3)
    dataset_1 = Linkage::Dataset.new("foo:/bar", "baz")

    field_1.expects(:clone).returns(mock('field 1 clone', :dataset= => nil))
    field_2.expects(:clone).returns(mock('field 2 clone', :dataset= => nil))
    field_3.expects(:clone).returns(mock('field 3 clone', :dataset= => nil))
    dataset_2 = dataset_1.clone
    dataset_2.fields.each_with_index do |field, i|
      assert !field.equal?(dataset_1.fields[i])
    end
  end
end
