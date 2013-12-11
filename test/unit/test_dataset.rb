require 'helper'

class UnitTests::TestDataset < Test::Unit::TestCase
  def setup
    super
    @schema = [
      [:id, {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil}],
      [:first_name, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(255)", :type=>:string, :ruby_default=>nil}],
      [:last_name, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(255)", :type=>:string, :ruby_default=>nil}]
    ]
    @dataset = stub('Sequel dataset', :first_source_table => :foo)
    @database = stub('database', :schema => @schema, :[] => @dataset, :extend => nil)
    @dataset.stubs(:db).returns(@database)
    Sequel.stubs(:connect).returns(@database)
    @field_set = stub("field set")
    Linkage::FieldSet.stubs(:new).returns(@field_set)
  end

  test "initialize with uri and table name" do
    Sequel.expects(:connect).with('foo:/bar', {:foo => 'bar'}).returns(@database)
    @database.expects(:extend).with(Sequel::Collation)
    @database.expects(:[]).with(:foo).returns(@dataset)
    Linkage::FieldSet.expects(:new).with(kind_of(Linkage::Dataset)).returns(@field_set)
    ds = Linkage::Dataset.new('foo:/bar', "foo", {:foo => 'bar'})
  end

  test "initialize with sequel dataset" do
    Linkage::Dataset.new(@dataset)
  end

  test "extend Sequel::Collation when initializing with sequel dataset" do
    @database.stubs(:kind_of?).with(Sequel::Collation).returns(false)
    @database.expects(:extend).with(Sequel::Collation)
    ds = Linkage::Dataset.new(@dataset)
  end

  test "don't extend already extended database" do
    @database.stubs(:kind_of?).with(Sequel::Collation).returns(true)
    @database.expects(:extend).with(Sequel::Collation).never
    ds = Linkage::Dataset.new(@dataset)
  end

  test "table_name" do
    ds = Linkage::Dataset.new('foo:/bar', "foo", {:foo => 'bar'})
    assert_equal :foo, ds.table_name
  end

  test "table_name when initialized from sequel dataset" do
    ds = Linkage::Dataset.new(@dataset)
    assert_equal :foo, ds.table_name
  end

  test "schema" do
    ds = Linkage::Dataset.new('foo:/bar', "foo", {:foo => 'bar'})
    @database.expects(:schema).with(:foo).returns(@schema)
    assert_equal @schema, ds.schema
  end

  test "schema when initialized from sequel dataset" do
    ds = Linkage::Dataset.new(@dataset)
    @database.expects(:schema).with(:foo).returns(@schema)
    assert_equal @schema, ds.schema
  end

  test "database_type" do
    ds = Linkage::Dataset.new('foo:/bar', "foo", {:foo => 'bar'})
    @dataset.stubs(:db).returns(@database)
    @database.expects(:database_type).returns(:foo)
    assert_equal :foo, ds.database_type
  end

  test "primary key" do
    ds = Linkage::Dataset.new('foo:/bar', "foo", {:foo => 'bar'})
    pk = stub('primary key field')
    @field_set.expects(:primary_key).returns(pk)
    assert_equal pk, ds.primary_key
  end
end
