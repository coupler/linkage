require 'helper'

module IntegrationTests
  class TestFunctions < Test::Unit::TestCase
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

    test "match functions" do
      # insert the test data
      database do |db|
        db.create_table(:foo) { primary_key(:id); String(:bar) }
        db[:foo].import([:id, :bar],
          Array.new(100) { |i| [i, "bar%s" % (" " * (i % 10))] })
      end

      ds = Linkage::Dataset.new(@tmpuri, "foo", :single_threaded => true)
      tmpuri = @tmpuri
      conf = ds.link_with(ds) do
        trim(lhs[:bar]).must == trim(rhs[:bar])
        save_results_in(tmpuri)
      end
      assert_equal :self, conf.linkage_type
      runner = Linkage::SingleThreadedRunner.new(conf)
      runner.execute

      database do |db|
        assert_equal 1, db[:groups].count
      end
    end

    test "strftime in sqlite" do
      #logger = Logger.new(STDERR)
      #database(:logger => logger) do |db|
      database do |db|
        db.create_table(:foo) { primary_key(:id); Date(:foo_date) }
        db.create_table(:bar) { primary_key(:id); String(:bar_string) }
        db[:foo].insert({:id => 1, :foo_date => Date.today})
        db[:bar].insert({:id => 1, :bar_string => Date.today.strftime("%Y-%m-%d")})
      end

      ds_1 = Linkage::Dataset.new(@tmpuri, "foo", :single_threaded => true)
      ds_2 = Linkage::Dataset.new(@tmpuri, "bar", :single_threaded => true)
      tmpuri = @tmpuri
      conf = ds_1.link_with(ds_2) do
        strftime(lhs[:foo_date], "%Y-%m-%d").must == rhs[:bar_string]
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
