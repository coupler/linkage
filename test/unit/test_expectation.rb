require 'helper'

class UnitTests::TestExpectation < Test::Unit::TestCase
  test "new must expectation with two fields" do
    Linkage::MustExpectation.new(:==, stub('field 1'), stub('field 2'))
  end
end
