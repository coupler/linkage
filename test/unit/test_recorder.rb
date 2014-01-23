require 'helper'

class UnitTests::TestRecorder < Test::Unit::TestCase
  def setup
    @result_set = stub('result set')
  end

  test "recording events from comparators" do
    recorder = Linkage::Recorder.new(@result_set, [:id_1, :id_2])
    comparator = stub('comparator')
    comparator.expects(:add_observer).with(recorder)
    recorder.listen_to(comparator)

    @result_set.expects(:add_score).with(1, 123, 456, 1)
    record_1 = { :id_1 => 123 }
    record_2 = { :id_2 => 456 }
    recorder.update(comparator, record_1, record_2, 1)

    comparator.expects(:delete_observer).with(recorder)
    recorder.stop_listening
  end
end
