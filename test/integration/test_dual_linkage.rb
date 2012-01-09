require 'helper'

module IntegrationTests
  class TestDualLinkage < Test::Unit::TestCase
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
      runner = Linkage::SingleThreadedRunner.new(conf)
      runner.execute

      database do |db|
        assert_equal 10, db[:groups].count
        db[:groups].order(:ssn).each_with_index do |row, i|
          assert_equal "12345678#{i%10}", row[:ssn]
        end

        assert_equal 200, db[:groups_records].count
        db[:groups_records].order(:group_id, :dataset, :record_id).each_with_index do |row, i|
          if i % 20 >= 10
            assert_equal 2, row[:dataset], row.inspect
          else
            assert_equal 1, row[:dataset], row.inspect
          end
          expected_group_id = i / 20 + 1
          assert_equal expected_group_id, row[:group_id], "Record #{row.inspect} should have been in group #{expected_group_id}"
        end
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

    test "handles MySQL's ignorance of trailing spaces when comparing strings" do
      pend
      if !test_config['mysql']
        omission("No MySQL test configuration found")
      end
      uri = "mysql2://%s:%s/%s?user=%s" % test_config['mysql'].values_at('host', 'port', 'database', 'user')
      Sequel.connect(uri) do |db|
        db.create_table!(:foo) { primary_key(:id); String(:one); String(:two) }
        db[:foo].import([:id, :one, :two], [[1, "", "test"], [2, "", "test"], [3, " ", "test "], [4, "", "test"], [5, "", "junk"]])

        db.create_table!(:bar) { primary_key(:id); String(:one); String(:two) }
        db[:bar].import([:id, :one, :two], [[1, "", "junk"]])

        db.run("DROP TABLE IF EXISTS groups")
        db.run("DROP TABLE IF EXISTS groups_records")
      end

      ds_1 = Linkage::Dataset.new(uri, "foo", :single_threaded => true)
      ds_2 = Linkage::Dataset.new(uri, "bar", :single_threaded => true)
      logger = Logger.new(STDERR)
      conf = ds_1.link_with(ds_2) do
        lhs[:one].must == rhs[:one]
        lhs[:two].must == rhs[:two]
        save_results_in(uri, :logger => logger)
      end

      runner = Linkage::SingleThreadedRunner.new(conf)
      runner.execute

      Sequel.connect(@tmpuri) do |db|
        assert_equal 1, db[:groups].count
      end
    end
  end
end
