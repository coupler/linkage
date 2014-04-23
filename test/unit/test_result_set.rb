require 'helper'

class TestResultSet < Test::Unit::TestCase
  test "default result set" do
    score_set = stub('score set')
    match_set = stub('match set')
    result_set = Linkage::ResultSet.new(score_set, match_set)
    assert_same score_set, result_set.score_set
    assert_same match_set, result_set.match_set
  end

  test "getting a registered class" do
    klass = new_result_set
    Linkage::ResultSet.register('foo', klass)
    assert_equal klass, Linkage::ResultSet['foo']
  end

  test "registered classes required to define score_set" do
    klass = new_result_set do
      undef :score_set
    end
    assert_raises(ArgumentError) { Linkage::ResultSet.register('foo', klass) }
  end

  test "registered classes required to define match_set" do
    klass = new_result_set do
      undef :match_set
    end
    assert_raises(ArgumentError) { Linkage::ResultSet.register('foo', klass) }
  end
end
