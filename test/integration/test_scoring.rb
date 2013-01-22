require 'helper'

module IntegrationTests
  class TestScoring < Test::Unit::TestCase
    test "stop scoring if must expectation fails" do
      database_for('sqlite') do |db|
        db.create_table(:foo) { primary_key(:id); Integer(:num) }
        db.create_table(:bar) { primary_key(:id); Integer(:num) }
        db[:foo].import([:id, :num], [[1, 1]])
        db[:bar].import([:id, :num], [[1, 5]])
      end

      db_opts = database_options_for('sqlite')
      dataset_1 = Linkage::Dataset.new(db_opts, "foo")
      dataset_2 = Linkage::Dataset.new(db_opts, "bar")
      conf = dataset_1.link_with(dataset_2) do
        lhs[:num].must_not be_within(5).of(rhs[:num])
        lhs[:num].must be_within(5).of(rhs[:num])
        save_results_in(db_opts)
      end

      runner = Linkage::SingleThreadedRunner.new(conf)
      runner.execute

      database_for('sqlite') do |db|
        assert_equal db[:scores].count, 1
        record = db[:scores].first
        assert_equal 1, record[:score]
      end
    end
  end
end
