require 'helper'

class TestMatchSet < Test::Unit::TestCase
  test "add_match raises NotImplementedError" do
    match_set = Linkage::MatchSet.new
    assert_raises(NotImplementedError) do
      match_set.add_match('foo', 'bar', 'baz')
    end
  end

  test "getting a registered class" do
    klass = new_match_set
    Linkage::MatchSet.register('foo', klass)
    assert_equal klass, Linkage::MatchSet['foo']
  end

  test "registered classes required to define add_match" do
    klass = new_match_set do
      remove_method :add_match
    end
    assert_raises(ArgumentError) { Linkage::MatchSet.register('foo', klass) }
  end
end
