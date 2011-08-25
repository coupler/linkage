require 'helper'

class UnitTests::TestSingleThreadedRunner < Test::Unit::TestCase
  test "subclass of Runner" do
    assert_equal Linkage::Runner, Linkage::SingleThreadedRunner.superclass
  end

  test "responds to execute" do
    assert_include Linkage::SingleThreadedRunner.public_instance_methods(false), :execute
  end
end
