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

    test "one-field equality on single threaded runner" do
      # create the test data
      database do |db|
        db.create_table(:foo) { primary_key(:id); String(:ssn) }
        db[:foo].import([:id, :ssn],
          Array.new(100) { |i| [i, "12345678#{i%10}"] })

        db.create_table(:bar) { primary_key(:id); String(:ssn) }
        db[:bar].import([:id, :ssn],
          Array.new(100) { |i| [i, "12345678#{i%10}"] })
      end

      result_set = Linkage::ResultSet['csv'].new(@tmpdir)
      ds_1 = Linkage::Dataset.new(@tmpuri, "foo", :single_threaded => true)
      ds_2 = Linkage::Dataset.new(@tmpuri, "bar", :single_threaded => true)
      tmpuri = @tmpuri
      conf = ds_1.link_with(ds_2, result_set) do |conf|
        conf.compare([:ssn], [:ssn], :equal_to)
        conf.algorithm = :mean
        conf.threshold = 1.0
      end

      runner = Linkage::Runner.new(conf)
      runner.execute

      score_csv = CSV.read(File.join(@tmpdir, 'scores.csv'), :headers => true)
      assert_equal 1000, score_csv.length
      score_csv.each do |row|
        id_1 = row['id_1'].to_i
        id_2 = row['id_2'].to_i
        assert (id_1 % 10) == (id_2 % 10)
      end

      match_csv = CSV.read(File.join(@tmpdir, 'matches.csv'), :headers => true)
      assert_equal 1000, match_csv.length
      match_csv.each do |row|
        id_1 = row['id_1'].to_i
        id_2 = row['id_2'].to_i
        assert (id_1 % 10) == (id_2 % 10)
      end
    end
  end
end
