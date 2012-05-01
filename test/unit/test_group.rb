require 'helper'

class UnitTests::TestGroup < Test::Unit::TestCase
  test "initialize" do
    g = Linkage::Group.new({:test => 'test'}, {:count => 1, :id => 456})
    assert_equal({:test => 'test'}, g.values)
    assert_equal 1, g.count
    assert_equal 456, g.id
  end
end
