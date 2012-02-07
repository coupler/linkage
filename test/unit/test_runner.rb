require 'helper'

class UnitTests::TestRunner < Test::Unit::TestCase
  def setup
    @result_set = stub("result set")
    @config = stub("configuration", :result_set => @result_set)
  end

  test "initialization creates a result set" do
    runner = Linkage::Runner.new(@config)
  end

  test "initialization with deprecated uri and options" do
    @config.expects(:save_results_in).with("foo:/results", {:foo => 'bar'})
    Linkage::Runner.any_instance.expects(:warn)
    runner = Linkage::Runner.new(@config, "foo:/results", {:foo => 'bar'})
  end

  test "execute raises error" do
    runner = Linkage::Runner.new(@config)
    assert_raise_kind_of(NotImplementedError) { runner.execute }
  end

  test "result_set gets ResultSet from config" do
    runner = Linkage::Runner.new(@config)
    @config.expects(:result_set).returns(@result_set)
    assert_equal @result_set, runner.result_set
  end
end
