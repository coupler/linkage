require 'helper'

class UnitTests::TestMatchRecorder < Test::Unit::TestCase
  def setup
    @match_set = stub('match set')
    @matcher = stub('matcher')
  end

  test "recording events from a matcher" do
    match_recorder = Linkage::MatchRecorder.new(@matcher, @match_set)

    @matcher.expects(:add_observer).with(match_recorder)
    @match_set.expects(:open_for_writing)
    match_recorder.start

    @match_set.expects(:add_match).with(123, 456, 1)
    match_recorder.update(123, 456, 1)

    @matcher.expects(:delete_observer).with(match_recorder)
    @match_set.expects(:close)
    match_recorder.stop
  end
end
