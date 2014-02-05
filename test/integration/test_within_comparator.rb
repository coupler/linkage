require 'helper'

module IntegrationTests
  class TestWithinComparator < Test::Unit::TestCase
    def setup
      @tmpdir = Dir.mktmpdir('linkage')
    end

    def teardown
      FileUtils.remove_entry_secure(@tmpdir)
    end

    test "within comparator" do
      database_for('sqlite') do |db|
        db.create_table(:foo) { primary_key(:id); Integer(:num) }
        db.create_table(:bar) { primary_key(:id); Integer(:num) }
        db[:foo].import([:id, :num], (1..10).collect { |i| [i, i] })
        db[:bar].import([:id, :num], (1..10).collect { |i| [i, i] })
      end

      result_set = Linkage::ResultSet['csv'].new(@tmpdir)
      db_opts = database_options_for('sqlite')
      dataset_1 = Linkage::Dataset.new(db_opts, "foo")
      dataset_2 = Linkage::Dataset.new(db_opts, "bar")
      conf = dataset_1.link_with(dataset_2, result_set) do |conf|
        conf.within(:num, :num, 5)
      end

      runner = Linkage::SingleThreadedRunner.new(conf)
      runner.execute

      score_csv = CSV.read(File.join(@tmpdir, 'scores.csv'), :headers => true)
      assert_equal 100, score_csv.length
      score_csv.each do |row|
        assert_equal "1", row['comparator']
        # ids same as values
        id_1 = row['id_1'].to_i
        id_2 = row['id_2'].to_i
        if (id_2 - id_1).abs <= 5
          assert_equal 1, row['score'].to_i, row
        else
          assert_equal 0, row['score'].to_i
        end
      end
    end
  end
end
