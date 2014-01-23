require 'helper'

class TestScoreSet < Test::Unit::TestCase
  test "add_score raises NotImplementedError" do
    score_set = Linkage::ScoreSet.new
    assert_raises(NotImplementedError) do
      score_set.add_score('foo', 'bar', 'baz', 'qux')
    end
  end

  test "each_pair raises NotImplementedError" do
    score_set = Linkage::ScoreSet.new
    assert_raises(NotImplementedError) do
      score_set.each_pair { |x| }
    end
  end

  test "getting a registered class" do
    klass = new_score_set
    Linkage::ScoreSet.register('foo', klass)
    assert_equal klass, Linkage::ScoreSet['foo']
  end

  test "registered classes required to define add_score" do
    klass = new_score_set do
      remove_method :add_score
    end
    assert_raises(ArgumentError) { Linkage::ScoreSet.register('foo', klass) }
  end

  test "registered classes required to define each_pair" do
    klass = new_score_set do
      remove_method :each_pair
    end
    assert_raises(ArgumentError) { Linkage::ScoreSet.register('foo', klass) }
  end
end
