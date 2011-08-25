require 'helper'

class UnitTests::TestUtils < Test::Unit::TestCase
  include Linkage::Utils

  test "merge two identical fields" do
    field_1 = [:id, {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil}]
    field_2 = [:id, {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil}]
  end
end
