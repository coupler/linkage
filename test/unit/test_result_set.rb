require 'helper'

class TestResultSet < Test::Unit::TestCase
  def setup
    @config = stub('configuration', {
      :results_uri => 'foo://bar',
      :results_uri_options => {:blah => 'junk'}
    })
  end

  test "creating a result set with a configuration" do
    result_set = Linkage::ResultSet.new(@config)
  end

  test "records?" do
    pend
  end
end
