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
    @database = stub('database', :schema => @schema, :[] => @dataset)
    Sequel.stubs(:connect).returns(@database)
    @field_set = stub("field set")
    Linkage::FieldSet.stubs(:new).returns(@field_set)
  end

  test "initialize with uri and table name" do
    Sequel.expects(:connect).with('foo:/bar', {:foo => 'bar'}).returns(@database)
    @database.expects(:schema).with(:foo).returns(@schema)
    @database.expects(:[]).with(:foo).returns(@dataset)
    Linkage::FieldSet.expects(:new).with(@schema).returns(@field_set)
    ds = Linkage::Dataset.new('foo:/bar', "foo", {:foo => 'bar'})
  end

  test "table_name" do
    ds = Linkage::Dataset.new('foo:/bar', "foo", {:foo => 'bar'})
    assert_equal :foo, ds.table_name
  end

  test "adapter_scheme" do
    ds = Linkage::Dataset.new('foo:/bar', "foo", {:foo => 'bar'})
    @dataset.stubs(:db).returns(@database)
    @database.expects(:adapter_scheme).returns(:foo)
    assert_equal :foo, ds.adapter_scheme
  end

  test "add match expression" do
    ds_1 = Linkage::Dataset.new('foo:/bar', "foo", {:foo => 'bar'})
    @dataset.expects(:clone).returns(@dataset)
    ds_2 = ds_1.match(:foo)
    assert_not_same ds_1, ds_2
    assert_not_equal ds_1.instance_variable_get(:@_match),
      ds_2.instance_variable_get(:@_match)
  end

  test "add match expression with alias, then each_group" do
    ds_1 = Linkage::Dataset.new('foo:/bar', "foo", {:foo => 'bar'})
    @dataset.expects(:clone).returns(@dataset)
    ds_2 = ds_1.match(:foo, :aliased_foo)
    @dataset.expects(:group_and_count).with(:foo.as(:aliased_foo)).returns(@dataset)
    @dataset.expects(:having).returns(@dataset)
    @dataset.expects(:each).yields({:aliased_foo => 123, :count => 1})
    ds_2.each_group { |g| }
  end

  test "group_by_matches" do
    ds = Linkage::Dataset.new('foo:/bar', "foo", {:foo => 'bar'})

    @dataset.expects(:clone).returns(@dataset)
    ds = ds.match(:foo)
    @dataset.expects(:group).with(:foo).returns(@dataset)

    ds.group_by_matches
  end
end
