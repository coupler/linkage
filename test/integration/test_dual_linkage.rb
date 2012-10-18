require 'helper'

module IntegrationTests
  class TestDualLinkage < Test::Unit::TestCase
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
      # create the test data
      database do |db|
        db.create_table(:foo) { primary_key(:id); String(:ssn) }
        db[:foo].import([:id, :ssn],
          Array.new(100) { |i| [i, "12345678#{i%10}"] })

        db.create_table(:bar) { primary_key(:id); String(:ssn) }
        db[:bar].import([:id, :ssn],
          Array.new(100) { |i| [i, "12345678#{i%10}"] })
      end

      ds_1 = Linkage::Dataset.new(@tmpuri, "foo", :single_threaded => true)
      ds_2 = Linkage::Dataset.new(@tmpuri, "bar", :single_threaded => true)
      tmpuri = @tmpuri
      conf = ds_1.link_with(ds_2) do
        lhs[:ssn].must == rhs[:ssn]
        save_results_in(tmpuri)
      end
      assert_equal :dual, conf.linkage_type

      runner = Linkage::SingleThreadedRunner.new(conf)
      runner.execute

      database do |db|
        assert_equal 10, db[:groups].count
        db[:groups].order(:ssn).each_with_index do |row, i|
          assert_equal "12345678#{i%10}", row[:ssn]
        end

        #assert_equal 200, db[:groups_records].count
        #db[:groups_records].order(:group_id, :dataset, :record_id).each_with_index do |row, i|
          #if i % 20 >= 10
            #assert_equal 2, row[:dataset], row.inspect
          #else
            #assert_equal 1, row[:dataset], row.inspect
          #end
          #expected_group_id = i / 20 + 1
          #assert_equal expected_group_id, row[:group_id], "Record #{row.inspect} should have been in group #{expected_group_id}"
        #end
      end
    end

    test "don't ignore 1-record groups before the combining phase" do
      # create the test data
      database do |db|
        db.create_table(:foo) { primary_key(:id); String(:ssn) }
        db[:foo].import([:id, :ssn],
          Array.new(100) { |i| [i, "1234567%03d" % i] })

        db.create_table(:bar) { primary_key(:id); String(:ssn) }
        db[:bar].import([:id, :ssn],
          Array.new(100) { |i| [i, "1234567%03d" % i] })
      end

      ds_1 = Linkage::Dataset.new(@tmpuri, "foo", :single_threaded => true)
      ds_2 = Linkage::Dataset.new(@tmpuri, "bar", :single_threaded => true)
      tmpuri = @tmpuri
      conf = ds_1.link_with(ds_2) do
        lhs[:ssn].must == rhs[:ssn]
        save_results_in(tmpuri)
      end
      runner = Linkage::SingleThreadedRunner.new(conf)
      runner.execute

      database do |db|
        assert_equal 100, db[:groups].count
        db[:groups].order(:ssn).each_with_index do |row, i|
          assert_equal "1234567%03d" % i, row[:ssn]
        end
      end
    end

    test "reacts properly when using two databases with different string equality methods" do
      foo_logger = nil #prefixed_logger("FOO")
      bar_logger = nil #prefixed_logger("BAR")

      database_for('mysql', :logger => foo_logger) do |db|
        db.create_table!(:foo) do
          primary_key(:id)
          String :baz, :collate => "latin1_swedish_ci"
        end
        db[:foo].import([:id, :baz], [
          [1, "tEst"],
          [2, "teSt"],
          [3, "tesT "],
          [4, "TEST"],
          [5, "junk"]
        ])
      end

      database_for('mysql', :logger => bar_logger) do |db|
        db.create_table!(:bar) do
          primary_key(:id)
          String :baz, :collate => "latin1_swedish_ci"
        end
        db[:bar].import([:id, :baz], [
          [1, "Test  "],
          [2, "tEst "],
          [3, "teSt"],
          [4, "TEST"],
          [5, "junk"]
        ])
      end

      options = database_options_for('mysql')
      ds_1 = Linkage::Dataset.new(options, "foo", :logger => foo_logger)
      ds_2 = Linkage::Dataset.new(options, "bar", :logger => bar_logger)
      tmpuri = @tmpuri
      results_logger = nil #prefixed_logger("RESULTS")
      conf = ds_1.link_with(ds_2) do
        lhs[:baz].must == rhs[:baz]
        save_results_in(tmpuri, :logger => results_logger)
      end

      runner = Linkage::SingleThreadedRunner.new(conf)
      runner.execute

      database do |db|
        assert_equal 2, db[:groups].count
      end
    end
  end
end
