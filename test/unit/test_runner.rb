require 'helper'

class UnitTests::TestRunner < Test::Unit::TestCase
  def setup
    @config = stub("configuration")
    @result_set = stub('result set')
  end

  test "initialization" do
    runner = Linkage::Runner.new(@config, @result_set)
    assert_same @config, runner.config
    assert_same @result_set, runner.result_set
  end

  test "execute raises error" do
    runner = Linkage::Runner.new(@config, @result_set)
    assert_raise_kind_of(NotImplementedError) { runner.execute }
  end
end
