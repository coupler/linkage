require 'helper'

module IntegrationTests
  class TestCrossLinkage < Test::Unit::TestCase
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

    test "one mandatory field equality on single threaded runner" do
      # insert the test data
      database do |db|
        db.create_table(:foo) { primary_key(:id); Integer(:foo); Integer(:bar) }
        db[:foo].import([:id, :foo, :bar],
          Array.new(100) { |i| [i, i % 10, i % 5] })
      end

      ds = Linkage::Dataset.new(@tmpuri, "foo", :single_threaded => true)

      tmpuri = @tmpuri
      conf = ds.link_with(ds) do
        lhs[:foo].must == rhs[:bar]
        save_results_in(tmpuri, :single_threaded => true)
      end
      assert_equal :cross, conf.linkage_type
      runner = Linkage::SingleThreadedRunner.new(conf)
      runner.execute

      database do |db|
        assert_equal 5, db[:groups].count, PP.pp(db[:groups].all, "")
        db[:groups].order(:foo_bar).each_with_index do |row, i|
          assert_equal i, row[:foo_bar]
        end

        assert_equal 1000, db[:matches].count
        db[:matches].order(:record_1_id, :record_2_id).each do |row|
          assert_equal row[:record_1_id] % 10, row[:record_2_id] % 5
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
      tmpuri = @tmpuri
      conf = ds.link_with(ds) do
        lhs[:foo].must == rhs[:foo]
        lhs[:bar].must == 0
        rhs[:bar].must == 10
        save_results_in(tmpuri)
      end
      runner = Linkage::SingleThreadedRunner.new(conf)
      runner.execute

      database do |db|
        assert_equal 1, db[:groups].count
      end
    end
  end
end
