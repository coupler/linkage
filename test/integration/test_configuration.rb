require 'helper'

module IntegrationTests
  class TestConfiguration < Test::Unit::TestCase
    def setup
      @tmpdir = Dir.mktmpdir('linkage')
      @tmpuri = "sqlite://" + File.join(@tmpdir, "foo")
    end

    def database(options = {}, &block)
      Sequel.connect(@tmpuri, options, &block)
    end

    def teardown
      FileUtils.remove_entry_secure(@tmpdir)
    end

    test "case insensitive field names" do
      database do |db|
        db.create_table(:foo) { primary_key(:id); String(:foo); String(:bar) }
      end

      assert_nothing_raised do
        dataset = Linkage::Dataset.new(@tmpuri, "foo")
        tmpuri = @tmpuri
        conf = dataset.link_with(dataset) do
          lhs[:Foo].must == rhs[:baR]
          save_results_in(tmpuri)
        end
      end
    end
  end
end
