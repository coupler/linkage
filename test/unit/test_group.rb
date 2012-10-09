require 'helper'

class UnitTests::TestGroup < Test::Unit::TestCase
  test "initialize" do
    g = Linkage::Group.new({:test => 'test'}, {:count => 1, :id => 456})
    assert_equal({:test => 'test'}, g.values)
    assert_equal 1, g.count
    assert_equal 456, g.id
  end

  test "decollate strings" do
    field = stub('test field', :ruby_type => { :type => String, :opts => { :collate => :latin1_swedish_ci } }, :database_type => :mysql)
    group = Linkage::Group.new({:test => 'test'}, {:count => 1, :id => 456, :fields => [field]})
  end
end
