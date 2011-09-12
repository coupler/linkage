require 'helper'

module IntegrationTests
  class TestSelfLinkage < Test::Unit::TestCase
    def setup
      @tmpdir = Dir.mktmpdir('linkage')
      @tmpuri = "sqlite://" + File.join(@tmpdir, "foo")
      @db = Sequel.connect(@tmpuri)
      @db.create_table(:foo) { primary_key(:id); String(:ssn) }
    end

    def teardown
      @db.disconnect
      FileUtils.remove_entry_secure(@tmpdir)
    end

    test "one mandatory field equality on single threaded runner" do
      pend
      # insert the test data
      @db[:foo].import([:id, :ssn],
        Array.new(100) { |i| [i, "12345678#{i%10}"] })

      ds = Linkage::Dataset.new(@tmpuri, "foo")
      conf = ds.link_with(ds) do
        lhs[:ssn].must == rhs[:ssn]
      end
      runner = Linkage::SingleThreadedRunner.new(conf, @tmpuri)
      runner.execute

      tables = @db.tables
      assert_include tables, :groups
      assert_equal 100, @db[:groups].count

      expected_group_id = nil
      @db[:groups].order(:record_id).each do |row|
        if row[:record_id] % 10 == 0
          expected_group_id = row[:group_id]
        else
          assert_equal expected_group_id, row[:group_id]
        end
      end
    end
  end
end
