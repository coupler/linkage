require 'helper'

module IntegrationTests
  class TestWithinComparator < Test::Unit::TestCase
    test "within comparator with no simple expectations" do
      database_for('sqlite') do |db|
        db.create_table(:foo) { primary_key(:id); Integer(:num) }
        db.create_table(:bar) { primary_key(:id); Integer(:num) }
        db[:foo].import([:id, :num], (1..10).collect { |i| [i, i] })
        db[:bar].import([:id, :num], (1..10).collect { |i| [i, i] })
      end

      db_opts = database_options_for('sqlite')
      dataset_1 = Linkage::Dataset.new(db_opts, "foo")
      dataset_2 = Linkage::Dataset.new(db_opts, "bar")
      conf = dataset_1.link_with(dataset_2) do
        lhs[:num].must be_within(5).of(rhs[:num])
        save_results_in(db_opts)
      end

      runner = Linkage::SingleThreadedRunner.new(conf)
      runner.execute

      database_for('sqlite') do |db|
        assert_equal db[:scores].count, 100
        db[:scores].order(:record_1_id, :record_2_id).each do |score|
          if (score[:record_2_id] - score[:record_1_id]).abs <= 5
            assert_equal 1, score[:score], score.inspect
          else
            assert_equal 0, score[:score], score.inspect
          end
        end
      end
    end

    test "within comparator with simple expectations" do
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
        lhs[:num].must be_within(5).of(rhs[:num])
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

    test "within comparator with simple expectations and functions" do
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
