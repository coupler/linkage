require 'helper'

class TestResultSet < Test::Unit::TestCase
  test "score_set raises NotImplementedError" do
    result_set = Linkage::ResultSet.new
    assert_raises(NotImplementedError) do
      result_set.score_set
    end
  end

  test "match_set raises NotImplementedError" do
    result_set = Linkage::ResultSet.new
    assert_raises(NotImplementedError) do
      result_set.match_set
    end
  end

  test "getting a registered class" do
    klass = new_result_set
    Linkage::ResultSet.register('foo', klass)
    assert_equal klass, Linkage::ResultSet['foo']
  end

  test "registered classes required to define score_set" do
    klass = new_result_set do
      remove_method :score_set
    end
    assert_raises(ArgumentError) { Linkage::ResultSet.register('foo', klass) }
  end

  test "registered classes required to define match_set" do
    klass = new_result_set do
      remove_method :match_set
    end
    assert_raises(ArgumentError) { Linkage::ResultSet.register('foo', klass) }
  end
end
