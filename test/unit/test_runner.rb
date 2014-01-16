require 'helper'

class UnitTests::TestRunner < Test::Unit::TestCase
  def setup
    @config = stub("configuration")
  end

  test "initialization" do
    runner = Linkage::Runner.new(@config)
    assert_same @config, runner.config
  end

  test "execute raises error" do
    runner = Linkage::Runner.new(@config)
    assert_raise_kind_of(NotImplementedError) { runner.execute }
  end
end
