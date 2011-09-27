require 'helper'

module IntegrationTests
  class TestCrossLinkage < Test::Unit::TestCase
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
        db.create_table(:foo) { primary_key(:id); Integer(:foo); Integer(:bar) }
        db[:foo].import([:id, :foo, :bar],
          Array.new(100) { |i| [i, i % 10, i % 5] })
      end

      ds = Linkage::Dataset.new(@tmpuri, "foo", :single_threaded => true)
      conf = ds.link_with(ds) do
        lhs[:foo].must == rhs[:bar]
      end
      runner = Linkage::SingleThreadedRunner.new(conf, @tmpuri)
      runner.execute

      database do |db|
        assert_equal 5, db[:groups].count
        db[:groups].order(:foo_bar).each_with_index do |row, i|
          assert_equal i, row[:foo_bar]
        end

        assert_equal 150, db[:groups_records].count
        db[:groups_records].order(:group_id, :dataset, :record_id).each_with_index do |row, i|
          expected_group_id = (row[:record_id] % 5) + 1
          assert_equal expected_group_id, row[:group_id], "Record #{row[:record_id]} should have been in group #{expected_group_id}"
        end
      end
    end

    test "match same field with different filters" do
      database do |db|
        db.create_table(:foo) { primary_key(:id); Integer(:foo); Integer(:bar) }
        db[:foo].import([:id, :foo, :bar],
          Array.new(100) { |i| [i, i % 10, i % 20] })
      end

      ds = Linkage::Dataset.new(@tmpuri, "foo", :single_threaded => true)
      conf = ds.link_with(ds) do
        lhs[:foo].must == rhs[:foo]
        lhs[:bar].must == 0
        rhs[:bar].must == 10
      end
      runner = Linkage::SingleThreadedRunner.new(conf, @tmpuri)
      runner.execute

      database do |db|
        assert_equal 1, db[:groups].count
      end
    end
  end
end
