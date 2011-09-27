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

      ds = Linkage::Dataset.new(@tmpuri, "foo", :single_threaded => true)
      conf = ds.link_with(ds) do
        lhs[:ssn].must == rhs[:ssn]
      end
      runner = Linkage::SingleThreadedRunner.new(conf, @tmpuri)
      runner.execute

      database do |db|
        assert_equal 10, db[:groups].count
        db[:groups].order(:ssn).each_with_index do |row, i|
          assert_equal "12345678#{i%10}", row[:ssn]
        end

        assert_equal 100, db[:groups_records].count
        expected_group_id = nil
        db[:groups_records].order(:record_id).each do |row|
          expected_group_id = (row[:record_id] % 10) + 1
          assert_equal expected_group_id, row[:group_id], "Record #{row[:record_id]} should have been in group #{expected_group_id}"
        end
      end
    end

    test "two mandatory field equalities on single threaded runner" do
      # insert the test data
      database do |db|
        db.create_table(:foo) { primary_key(:id); String(:ssn); Date(:dob) }
        db[:foo].import([:id, :ssn, :dob],
          Array.new(100) { |i| [i, "12345678#{i%10}", Date.civil(1985, 1, (i % 20) + 1)] })
      end

      ds = Linkage::Dataset.new(@tmpuri, "foo", :single_threaded => true)
      conf = ds.link_with(ds) do
        lhs[:ssn].must == rhs[:ssn]
        lhs[:dob].must == rhs[:dob]
      end
      runner = Linkage::SingleThreadedRunner.new(conf, @tmpuri)
      runner.execute

      database do |db|
        assert_equal 20, db[:groups].count
        db[:groups].order(:ssn).each_with_index do |row, i|
          assert_equal "12345678#{i/2}", row[:ssn]
          assert_equal Date.civil(1985, 1, i / 2 + 1 + (i % 2 == 0 ? 0 : 10)), row[:dob]
        end

        assert_equal 100, db[:groups_records].count
        expected_group_id = nil
        db[:groups_records].order(:record_id).each do |row|
          v = row[:record_id] % 20
          expected_group_id = v < 10 ? 1 + 2 * v : 2 * (v % 10 + 1)
          assert_equal expected_group_id, row[:group_id], "Record #{row[:record_id]} should have been in group #{expected_group_id}"
        end
      end
    end

    test "one mandatory field equality on single threaded runner, with filter" do
      # insert the test data
      database do |db|
        db.create_table(:foo) { primary_key(:id); String(:ssn); Integer(:mod_5) }
        db[:foo].import([:id, :ssn, :mod_5],
          Array.new(100) { |i| [i, "12345678#{i%10}", i % 5] })
      end

      ds = Linkage::Dataset.new(@tmpuri, "foo", :single_threaded => true)
      conf = ds.link_with(ds) do
        lhs[:ssn].must == rhs[:ssn]
        lhs[:mod_5].must == 3
      end
      runner = Linkage::SingleThreadedRunner.new(conf, @tmpuri)
      runner.execute

      database do |db|
        assert_equal 2, db[:groups].count
        db[:groups].order(:ssn).each_with_index do |row, i|
          assert_equal "12345678#{(i * 5) + 3}", row[:ssn]
        end

        assert_equal 20, db[:groups_records].count
        expected_group_id = nil
        db[:groups_records].order(:record_id).each do |row|
          expected_group_id = (row[:record_id] / 5) % 2 + 1
          assert_equal expected_group_id, row[:group_id], "Record #{row[:record_id]} should have been in group #{expected_group_id}"
        end
      end
    end

    test "one mandatory field equality on single threaded runner, with inequality filters" do
      # insert the test data
      database do |db|
        db.create_table(:foo) { primary_key(:id); String(:ssn); Integer(:mod_5) }
        db[:foo].import([:id, :ssn, :mod_5],
          Array.new(100) { |i| [i, "12345678#{i%10}", i % 5] })
      end

      ds = Linkage::Dataset.new(@tmpuri, "foo", :single_threaded => true)
      conf = ds.link_with(ds) do
        lhs[:ssn].must == rhs[:ssn]
        lhs[:mod_5].must > 2
        lhs[:mod_5].must <= 3
      end
      runner = Linkage::SingleThreadedRunner.new(conf, @tmpuri)
      runner.execute

      database do |db|
        assert_equal 2, db[:groups].count
        db[:groups].order(:ssn).each_with_index do |row, i|
          assert_equal "12345678#{(i * 5) + 3}", row[:ssn]
        end

        assert_equal 20, db[:groups_records].count
        expected_group_id = nil
        db[:groups_records].order(:record_id).each do |row|
          expected_group_id = (row[:record_id] / 5) % 2 + 1
          assert_equal expected_group_id, row[:group_id], "Record #{row[:record_id]} should have been in group #{expected_group_id}"
        end
      end
    end

    test "one mandatory field equality on single threaded runner, with field filter" do
      # insert the test data
      database do |db|
        db.create_table(:foo) { primary_key(:id); String(:ssn); Integer(:mod_5); Integer(:mod_20) }
        db[:foo].import([:id, :ssn, :mod_5, :mod_20],
          Array.new(100) { |i| [i, "123456789#{i%10}", i % 5, i % 20] })
      end

      ds = Linkage::Dataset.new(@tmpuri, "foo", :single_threaded => true)
      conf = ds.link_with(ds) do
        lhs[:ssn].must == rhs[:ssn]
        lhs[:mod_5].must == lhs[:mod_20]
      end
      assert_equal :self, conf.linkage_type
      runner = Linkage::SingleThreadedRunner.new(conf, @tmpuri)
      runner.execute

      database do |db|
        assert_equal 5, db[:groups].count
        db[:groups].order(:ssn).each_with_index do |row, i|
          assert_equal "123456789#{i}", row[:ssn]
        end

        assert_equal 25, db[:groups_records].count
        expected_group_id = nil
        db[:groups_records].order(:record_id).each do |row|
          expected_group_id = row[:record_id] % 5 + 1
          assert_equal expected_group_id, row[:group_id], "Record #{row[:record_id]} should have been in group #{expected_group_id}"
        end
      end
    end

    test "one mandatory field equality on single threaded runner, with identical filters" do
      # insert the test data
      database do |db|
        db.create_table(:foo) { primary_key(:id); String(:ssn); Integer(:mod_5); Integer(:mod_20) }
        db[:foo].import([:id, :ssn, :mod_5, :mod_20],
          Array.new(100) { |i| [i, "123456789#{i%10}", i % 5, i % 20] })
      end

      ds = Linkage::Dataset.new(@tmpuri, "foo", :single_threaded => true)
      conf = ds.link_with(ds) do
        lhs[:ssn].must == rhs[:ssn]
        lhs[:mod_5].must == lhs[:mod_20]
        rhs[:mod_5].must == rhs[:mod_20]
      end
      assert_equal :self, conf.linkage_type
      runner = Linkage::SingleThreadedRunner.new(conf, @tmpuri)
      runner.execute

      database do |db|
        assert_equal 5, db[:groups].count
        db[:groups].order(:ssn).each_with_index do |row, i|
          assert_equal "123456789#{i}", row[:ssn]
        end

        assert_equal 25, db[:groups_records].count
        expected_group_id = nil
        db[:groups_records].order(:record_id).each do |row|
          expected_group_id = row[:record_id] % 5 + 1
          assert_equal expected_group_id, row[:group_id], "Record #{row[:record_id]} should have been in group #{expected_group_id}"
        end
      end
    end
  end
end
