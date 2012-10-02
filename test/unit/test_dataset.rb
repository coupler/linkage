require 'helper'

class UnitTests::TestDataset < Test::Unit::TestCase
  def setup
    super
    @schema = [
      [:id, {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil}],
      [:first_name, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(255)", :type=>:string, :ruby_default=>nil}],
      [:last_name, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(255)", :type=>:string, :ruby_default=>nil}]
    ]
    @dataset = stub('Sequel dataset')
    @database = stub('database', :schema => @schema, :[] => @dataset, :extend => nil)
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

  test "table_name" do
    ds = Linkage::Dataset.new('foo:/bar', "foo", {:foo => 'bar'})
    assert_equal :foo, ds.table_name
  end

  test "database_type" do
    ds = Linkage::Dataset.new('foo:/bar', "foo", {:foo => 'bar'})
    @dataset.stubs(:db).returns(@database)
    @database.expects(:database_type).returns(:foo)
    assert_equal :foo, ds.database_type
  end

  test "add match object" do
    ds_1 = Linkage::Dataset.new('foo:/bar', "foo", {:foo => 'bar'})
    @dataset.expects(:clone).returns(@dataset)
    meta_object = stub('meta object')
    ds_2 = ds_1.match(meta_object)
    assert_not_same ds_1, ds_2
    assert_not_equal ds_1.instance_variable_get(:@_match),
      ds_2.instance_variable_get(:@_match)
  end

  test "add match expression with alias, then each_group" do
    ds_1 = Linkage::Dataset.new('foo:/bar', "foo", {:foo => 'bar'})
    @dataset.expects(:clone).returns(@dataset)
    meta_object = stub('meta_object', :to_expr => :foo)
    ds_2 = ds_1.match(meta_object, :aliased_foo)
    @dataset.expects(:group_and_count).with(:foo.as(:aliased_foo)).returns(@dataset)
    @dataset.expects(:having).returns(@dataset)
    @dataset.expects(:each).yields({:aliased_foo => 123, :count => 1})
    ds_2.each_group { |g| }
  end

  test "group_by_matches" do
    ds = Linkage::Dataset.new('foo:/bar', "foo", {:foo => 'bar'})

    @dataset.expects(:clone).returns(@dataset)
    meta_object = stub('meta object', :to_expr => :foo)
    ds = ds.match(meta_object)
    @dataset.expects(:group).with(:foo).returns(@dataset)

    ds.group_by_matches
  end

  test "dataset_for_group" do
    ds = Linkage::Dataset.new('foo:/bar', "foo", {:foo => 'bar'})
    @dataset.expects(:clone).returns(@dataset)
    meta_object = stub('meta object', :to_expr => :foo)
    ds = ds.match(meta_object, :foo_bar)

    group = stub("group", :values => {:foo_bar => 'baz'})
    filtered_dataset = stub('filtered dataset')
    @dataset.expects(:filter).with(:foo => 'baz').returns(filtered_dataset)
    assert_equal filtered_dataset, ds.dataset_for_group(group)
  end

  test "dataset_for_group without aliases" do
    ds = Linkage::Dataset.new('foo:/bar', "foo", {:foo => 'bar'})
    @dataset.expects(:clone).returns(@dataset)
    meta_object = stub('meta object', :to_expr => :foo)
    ds = ds.match(meta_object)

    group = stub("group", :values => {:foo => 'baz'})
    filtered_dataset = stub('filtered dataset')
    @dataset.expects(:filter).with(:foo => 'baz').returns(filtered_dataset)
    assert_equal filtered_dataset, ds.dataset_for_group(group)
  end
end
