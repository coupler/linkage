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
end
