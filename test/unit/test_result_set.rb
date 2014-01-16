require 'helper'

class TestResultSet < Test::Unit::TestCase
  test "add_score raises NotImplementedError" do
    result_set = Linkage::ResultSet.new
    assert_raises(NotImplementedError) do
      result_set.add_score('foo', 'bar', 'baz', 'qux')
    end
  end

  test "getting a registered class" do
    klass = new_result_set
    Linkage::ResultSet.register('foo', klass)
    assert_equal klass, Linkage::ResultSet['foo']
  end

  test "registered classes required to define add_score" do
    klass = new_result_set do
      remove_method :add_score
    end
    assert_raises(ArgumentError) { Linkage::ResultSet.register('foo', klass) }
  end
end
