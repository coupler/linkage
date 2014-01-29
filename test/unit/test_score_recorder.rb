require 'helper'

class UnitTests::TestScoreRecorder < Test::Unit::TestCase
  def setup
    @score_set = stub('score set')
  end

  test "recording events from comparators" do
    comparator = stub('comparator')
    score_recorder = Linkage::ScoreRecorder.new([comparator], @score_set, [:id_1, :id_2])

    comparator.expects(:add_observer).with(score_recorder)
    @score_set.expects(:open_for_writing)
    score_recorder.start

    @score_set.expects(:add_score).with(1, 123, 456, 1)
    record_1 = { :id_1 => 123 }
    record_2 = { :id_2 => 456 }
    score_recorder.update(comparator, record_1, record_2, 1)

    comparator.expects(:delete_observer).with(score_recorder)
    @score_set.expects(:close)
    score_recorder.stop
  end
end
