require 'helper'

module IntegrationTests
  class TestSelfLinkage < Test::Unit::TestCase
    def setup
      @tmpdir = Dir.mktmpdir('linkage')
      @tmpuri = "sqlite://" + File.join(@tmpdir, "foo")
    end

    def database(&block)
      Sequel.connect(@tmpuri, &block)
    end

    def teardown
      FileUtils.remove_entry_secure(@tmpdir)
    end

    test "one mandatory field equality on single threaded runner" do
      # insert the test data
      database do |db|
        db.create_table(:foo) { primary_key(:id); String(:ssn) }
        db[:foo].import([:id, :ssn],
          Array.new(100) { |i| [i, "12345678#{i%10}"] })
      end

      ds = Linkage::Dataset.new(@tmpuri, "foo")
      conf = ds.link_with(ds) do
        lhs[:ssn].must == rhs[:ssn]
      end
      runner = Linkage::SingleThreadedRunner.new(conf, @tmpuri)
      runner.execute

      database do |db|
        tables = db.tables
        assert_include tables, :groups
        assert_equal 100, db[:groups].count

        expected_group_id = nil
        db[:groups].order(:record_id).each do |row|
          expected_group_id = (row[:record_id] % 10) + 1
          assert_equal expected_group_id, row[:group_id], "Record #{row[:record_id]} should have been in group #{expected_group_id}"
        end
      end
    end
  end
end
