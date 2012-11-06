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

  test "set group_match" do
    ds_1 = Linkage::Dataset.new('foo:/bar', "foo", {:foo => 'bar'})
    @dataset.expects(:clone).returns(@dataset)
    meta_object = stub_instance(Linkage::MetaObject)
    ds_2 = ds_1.group_match(meta_object)
    assert_not_same ds_1, ds_2
    assert_not_equal ds_1.instance_variable_get(:@linkage_options),
      ds_2.instance_variable_get(:@linkage_options)
  end

  test "subsequent group_match replaces old options" do
    ds_1 = Linkage::Dataset.new('foo:/bar', "foo", {:foo => 'bar'})
    @dataset.expects(:clone).at_least_once.returns(@dataset)
    meta_object_1 = stub_instance(Linkage::MetaObject)
    ds_2 = ds_1.group_match(meta_object_1)
    assert_equal([{:meta_object => meta_object_1}], ds_2.linkage_options[:group_match])

    meta_object_2 = stub_instance(Linkage::MetaObject)
    ds_3 = ds_2.group_match(meta_object_2)
    assert_equal([{:meta_object => meta_object_2}], ds_3.linkage_options[:group_match])
  end

  test "group_match_more appends to group_match options" do
    ds_1 = Linkage::Dataset.new('foo:/bar', "foo", {:foo => 'bar'})
    @dataset.expects(:clone).at_least_once.returns(@dataset)
    meta_object_1 = stub_instance(Linkage::MetaObject)
    ds_2 = ds_1.group_match(meta_object_1)
    assert_equal([{:meta_object => meta_object_1}], ds_2.linkage_options[:group_match])

    meta_object_2 = stub_instance(Linkage::MetaObject)
    ds_3 = ds_2.group_match_more(meta_object_2)
    assert_equal([{:meta_object => meta_object_1}, {:meta_object => meta_object_2}], ds_3.linkage_options[:group_match])
  end

  test "group_by_matches" do
    ds = Linkage::Dataset.new('foo:/bar', "foo", {:foo => 'bar'})

    @dataset.expects(:clone).returns(@dataset)
    meta_object = stub_instance(Linkage::MetaObject, :to_expr => :foo)
    ds = ds.group_match(meta_object)
    @dataset.expects(:group).with(:foo).returns(@dataset)

    ds.group_by_matches
  end

  test "dataset_for_group" do
    ds = Linkage::Dataset.new('foo:/bar', "foo", {:foo => 'bar'})
    @dataset.expects(:clone).returns(@dataset)
    meta_object = stub_instance(Linkage::MetaObject, :to_expr => :foo)
    ds = ds.group_match({:meta_object => meta_object, :alias => :foo_bar})

    group = stub("group", :values => {:foo_bar => 'baz'})
    filtered_dataset = stub('filtered dataset')
    @dataset.expects(:filter).with(:foo => 'baz').returns(filtered_dataset)
    assert_equal filtered_dataset, ds.dataset_for_group(group)
  end

  test "dataset_for_group without aliases" do
    ds = Linkage::Dataset.new('foo:/bar', "foo", {:foo => 'bar'})
    @dataset.expects(:clone).returns(@dataset)
    meta_object = stub_instance(Linkage::MetaObject, :to_expr => :foo)
    ds = ds.group_match(meta_object)

    group = stub("group", :values => {:foo => 'baz'})
    filtered_dataset = stub('filtered dataset')
    @dataset.expects(:filter).with(:foo => 'baz').returns(filtered_dataset)
    assert_equal filtered_dataset, ds.dataset_for_group(group)
  end
end
