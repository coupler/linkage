require 'helper'

class UnitTests::TestMatcher < Test::Unit::TestCase
  def setup
    @score_set = stub('score set')
    @comparators = [stub('comparator 1'), stub('comparator 2'), stub('comparator 3')]
  end

  test "finding matches with mean and threshold" do
    matcher = Linkage::Matcher.new(@comparators, @score_set, :mean, 0.5)
    observer = stub('observer')
    observer.expects(:update).with(3, 4, 2.0 / 3)
    observer.expects(:update).with(4, 5, 1.0)
    matcher.add_observer(observer)

    pairs = [
      [1, 2, {1 => 1, 2 => 0, 3 => 0}],
      [2, 3, {1 => 0, 2 => 0, 3 => 0}],
      [3, 4, {1 => 0, 2 => 1, 3 => 1}],
      [4, 5, {1 => 1, 2 => 1, 3 => 1}]
    ]
    @score_set.expects(:each_pair).multiple_yields(*pairs)

    matcher.run
  end

  test "finding matches with mean and threshold with missing scores" do
    matcher = Linkage::Matcher.new(@comparators, @score_set, :mean, 0.5)
    observer = stub('observer')
    observer.expects(:update).with(3, 4, 2.0 / 3)
    observer.expects(:update).with(4, 5, 1.0)
    matcher.add_observer(observer)

    pairs = [
      [1, 2, {1 => 1, 3 => 0}],
      [2, 3, {1 => 0, 2 => 0, 3 => 0}],
      [3, 4, {2 => 1, 3 => 1}],
      [4, 5, {1 => 1, 2 => 1, 3 => 1}]
    ]
    @score_set.expects(:each_pair).multiple_yields(*pairs)

    matcher.run
  end
end
