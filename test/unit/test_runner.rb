require 'helper'

class UnitTests::TestRunner < Test::Unit::TestCase
  def setup
    @result_set = stub("result set")
    Linkage::ResultSet.stubs(:new).returns(@result_set)
  end

  test "initialization creates a result set" do
    conf = stub("configuration")
    Linkage::ResultSet.expects(:new).with(conf).returns(@result_set)
    runner = Linkage::Runner.new(conf)
  end

  test "initialization with deprecated uri and options" do
    conf = mock("configuration")
    conf.expects(:save_results_in).with("foo:/results", {:foo => 'bar'})
    Linkage::Runner.any_instance.expects(:warn)
    runner = Linkage::Runner.new(conf, "foo:/results", {:foo => 'bar'})
  end

  test "execute raises error" do
    conf = stub("configuration")
    runner = Linkage::Runner.new(conf)
    assert_raise_kind_of(NotImplementedError) { runner.execute }
  end
end
