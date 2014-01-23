require 'helper'

module IntegrationTests
  class TestWithinComparator < Test::Unit::TestCase
    test "within comparator" do
      database_for('sqlite') do |db|
        db.create_table(:foo) { primary_key(:id); Integer(:num) }
        db.create_table(:bar) { primary_key(:id); Integer(:num) }
        db[:foo].import([:id, :num], (1..10).collect { |i| [i, i] })
        db[:bar].import([:id, :num], (1..10).collect { |i| [i, i] })
      end

      # result set
      csv_file = Tempfile.new('linkage')
      csv_file.close
      score_set = Linkage::ScoreSet['csv'].new(csv_file.path)

      # config
      db_opts = database_options_for('sqlite')
      dataset_1 = Linkage::Dataset.new(db_opts, "foo")
      dataset_2 = Linkage::Dataset.new(db_opts, "bar")
      conf = dataset_1.link_with(dataset_2, score_set) do |conf|
        conf.within(:num, :num, 5)
      end

      runner = Linkage::SingleThreadedRunner.new(conf)
      runner.execute
      score_set.close

      csv = CSV.read(csv_file.path, :headers => true)
      assert_equal 100, csv.length
      csv.each do |row|
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

    test "within comparator with functions" do
      pend
      database_for('sqlite') do |db|
        db.create_table(:foo) { primary_key(:id); Integer(:num); String(:parity) }
        db.create_table(:bar) { primary_key(:id); Integer(:num); String(:parity)  }
        db[:foo].import([:id, :num, :parity], (1..10).collect { |i| [i, i, i % 2 == 0 ? "even" : "odd"] })
        db[:bar].import([:id, :num, :parity], (1..10).collect { |i| [i, i, i % 2 == 0 ? "even" : "odd"] })
      end

      db_opts = database_options_for('sqlite')
      dataset_1 = Linkage::Dataset.new(db_opts, "foo")
      dataset_2 = Linkage::Dataset.new(db_opts, "bar")
      conf = dataset_1.link_with(dataset_2) do
        lhs[:parity].must == rhs[:parity]
        cast(lhs[:num], 'integer').must be_within(5).of(cast(rhs[:num], 'integer'))
        save_results_in(db_opts)
      end

      runner = Linkage::SingleThreadedRunner.new(conf)
      runner.execute

      database_for('sqlite') do |db|
        assert_equal db[:scores].count, 50
        db[:scores].order(:record_1_id, :record_2_id).each do |score|
          if (score[:record_2_id] - score[:record_1_id]).abs <= 5
            assert_equal 1, score[:score]
          else
            assert_equal 0, score[:score]
          end
        end
      end
    end
  end
end
