require 'helper'

class UnitTests::TestConfiguration < Test::Unit::TestCase
  def setup
    super
    @schema = [
      [:id, {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil}],
      [:first_name, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(255)", :type=>:string, :ruby_default=>nil}],
      [:last_name, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(255)", :type=>:string, :ruby_default=>nil}]
    ]
    @ds_1 = stub('dataset 1', :primary_key => @schema[0], :schema => @schema)
    @ds_2 = stub('dataset 2', :primary_key => @schema[0], :schema => @schema)
  end

  test "groups_table_schema" do
    pend
    config = Linkage::Configuration.new(@ds_1, @ds_2)
    config.add_expectation(:must, :==, :lhs, :last_name, :rhs, :last_name)
    expected = [
      {:name => :record_id, :type => Integer, :opts => {}},
      {:name => :group_id, :type => Integer, :opts => {}},
      {:name => :last_name, :type => String, :opts => {:size => 255}},
    ]
    assert_equal expected, config.groups_table_schema
  end
end
