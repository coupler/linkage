require 'helper'

class UnitTests::TestMatcher < Test::Unit::TestCase
  def setup
    @score_set = stub('score set')
  end

  test "finding matches with mean and threshold" do
    matcher = Linkage::Matcher.new(@score_set, :mean, 0.5)
    observer = stub('observer')
    observer.expects(:update).with(3, 4, 2.0 / 3)
    observer.expects(:update).with(4, 5, 1.0)
    matcher.add_observer(observer)

    pairs = [
      [1, 2, [1, 0, 0]],
      [2, 3, [0, 0, 0]],
      [3, 4, [0, 1, 1]],
      [4, 5, [1, 1, 1]]
    ]
    @score_set.expects(:each_pair).multiple_yields(*pairs)

    matcher.run
  end
end
