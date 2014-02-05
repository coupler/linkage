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
    @dataset.responds_like_instance_of(Sequel::Dataset)
    @dataset.stubs(:kind_of?).with(Sequel::Dataset).returns(true)

    @database = stub('database', :schema => @schema, :[] => @dataset)
    @database.responds_like_instance_of(Sequel::Database)
    @database.stubs(:kind_of?).with(Sequel::Database).returns(true)
    @dataset.stubs(:db).returns(@database)
    Sequel.stubs(:connect).returns(@database)

    @field_set = stub("field set")
    Linkage::FieldSet.stubs(:new).returns(@field_set)
  end

  test "initialize with uri and table name" do
    Sequel.expects(:connect).with('foo:/bar', {:foo => 'bar'}).returns(@database)
    @database.expects(:[]).with(:foo).returns(@dataset)
    Linkage::FieldSet.expects(:new).with(kind_of(Linkage::Dataset)).returns(@field_set)
    ds = Linkage::Dataset.new('foo:/bar', "foo", {:foo => 'bar'})
    assert_equal @field_set, ds.field_set
  end

  test "initialize with sequel dataset" do
    @dataset.expects(:first_source_table).returns(:foo)
    @dataset.expects(:db).returns(@database)
    Linkage::FieldSet.expects(:new).with(kind_of(Linkage::Dataset)).returns(@field_set)
    ds = Linkage::Dataset.new(@dataset)
    assert_equal :foo, ds.table_name
    assert_equal @field_set, ds.field_set
  end

  test "initialize with sequel database and table name" do
    Sequel.unstub(:connect)
    Sequel.expects(:connect).never
    @database.expects(:[]).with(:foo).returns(@dataset)
    Linkage::FieldSet.expects(:new).with(kind_of(Linkage::Dataset)).returns(@field_set)
    ds = Linkage::Dataset.new(@database, "foo")
    assert_equal @field_set, ds.field_set
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

  test "link_with other" do
    ds_1 = Linkage::Dataset.new('foo:/bar', "foo", {:foo => 'bar'})
    ds_2 = Linkage::Dataset.new('foo:/bar', "bar", {:foo => 'bar'})
    result_set = stub('result set')
    conf = stub('configuration')
    Linkage::Configuration.expects(:new).with(ds_1, ds_2, result_set).returns(conf)
    actual = ds_1.link_with(ds_2, result_set) do |arg|
      assert_equal conf, arg
    end
    assert_equal actual, conf
  end

  test "link_with self" do
    ds = Linkage::Dataset.new('foo:/bar', "foo", {:foo => 'bar'})
    result_set = stub('result set')
    conf = stub('configuration')
    Linkage::Configuration.expects(:new).with(ds, nil, result_set).returns(conf)
    actual = ds.link_with(ds, result_set) do |arg|
      assert_equal conf, arg
    end
    assert_equal actual, conf
  end

  test "delegating" do
    dataset_2 = Sequel::Dataset.allocate
    @dataset.expects(:filter).with(:foo => 123).returns(dataset_2)
    ds_1 = Linkage::Dataset.new('foo:/bar', "foo", {:foo => 'bar'})
    ds_2 = ds_1.filter(:foo => 123)
    assert_kind_of Linkage::Dataset, ds_2
    assert_same dataset_2, ds_2.obj
  end
end
