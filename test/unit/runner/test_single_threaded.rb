require 'helper'

class UnitTests::TestSingleThreadedRunner < Test::Unit::TestCase
  test "subclass of Runner" do
    assert_equal Linkage::Runner, Linkage::SingleThreadedRunner.superclass
  end

  test "defines execute" do
    methods = Linkage::SingleThreadedRunner.public_instance_methods(false)
    assert methods.include?(:execute) || methods.include?("execute")
  end
end
