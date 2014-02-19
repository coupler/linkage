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

    test "one field equality on single threaded runner" do
      # insert the test data
      database do |db|
        db.create_table(:foo) { primary_key(:id); Integer(:foo); Integer(:bar) }
        db[:foo].import([:id, :foo, :bar],
          Array.new(100) { |i| [i, i % 10, i % 5] })
      end

      ds = Linkage::Dataset.new(@tmpuri, "foo", :single_threaded => true)

      result_set = Linkage::ResultSet['csv'].new(@tmpdir)
      conf = ds.link_with(ds, result_set) do |conf|
        conf.compare([:foo], [:bar], :equal_to)
        conf.algorithm = :mean
        conf.threshold = 1
      end

      runner = Linkage::Runner.new(conf)
      runner.execute

      score_csv = CSV.read(File.join(@tmpdir, 'scores.csv'), :headers => true)
      assert_equal 1000, score_csv.length
      score_csv.each do |row|
        id_1 = row['id_1'].to_i
        id_2 = row['id_2'].to_i
        assert (id_1 % 10) == (id_2 % 5)
        assert_equal "1", row['score']
      end

      match_csv = CSV.read(File.join(@tmpdir, 'matches.csv'), :headers => true)
      assert_equal 1000, match_csv.length
      match_csv.each do |row|
        id_1 = row['id_1'].to_i
        id_2 = row['id_2'].to_i
        assert (id_1 % 10) == (id_2 % 5)
        assert_equal "1", row['score']
      end
    end

    test "match same field with different filters" do
      database do |db|
        db.create_table(:foo) { primary_key(:id); Integer(:foo); Integer(:bar) }
        db[:foo].import([:id, :foo, :bar],
          Array.new(100) { |i| [i, i % 10, i % 20] })
      end

      result_set = Linkage::ResultSet['csv'].new(@tmpdir)
      ds = Linkage::Dataset.new(@tmpuri, "foo", :single_threaded => true)
      ds_1 = ds.filter(:bar => 0)
      ds_2 = ds.filter(:bar => 10)
      conf = ds_1.link_with(ds_2, result_set) do |conf|
        conf.compare([:foo], [:foo], :equal_to)
        conf.algorithm = :mean
        conf.threshold = 1
      end

      runner = Linkage::Runner.new(conf)
      runner.execute

      score_csv = CSV.read(File.join(@tmpdir, 'scores.csv'), :headers => true)
      assert_equal 25, score_csv.length
      score_csv.each do |row|
        id_1 = row['id_1'].to_i
        id_2 = row['id_2'].to_i
        assert (id_1 % 10) == (id_1 % 10)
      end

      match_csv = CSV.read(File.join(@tmpdir, 'matches.csv'), :headers => true)
      assert_equal 25, match_csv.length
      match_csv.each do |row|
        id_1 = row['id_1'].to_i
        id_2 = row['id_2'].to_i
        assert (id_1 % 10) == (id_1 % 10)
      end
    end
  end
end
