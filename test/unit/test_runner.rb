require 'helper'

class UnitTests::TestRunner < Test::Unit::TestCase
  test "initialization" do
    conf = stub("configuration")
    runner = Linkage::Runner.new(conf, "foo:/results")
  end

  test "execute raises error" do
    conf = stub("configuration")
    runner = Linkage::Runner.new(conf, "foo:/results")
    assert_raise_kind_of(NotImplementedError) { runner.execute }
  end
end
