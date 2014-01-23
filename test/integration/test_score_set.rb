require 'helper'

module IntegrationTests
  class TestScoreSet < Test::Unit::TestCase
    test "#create_tables! creates original_groups table when decollation is needed" do
      database_for('sqlite') do |db|
        db.create_table!(:foo) { primary_key(:id); String(:foo) }
      end

      database_for('mysql') do |db|
        db.create_table!(:foo) { primary_key(:id); String(:foo) }
      end

      dataset_1 = Linkage::Dataset.new(database_options_for('sqlite'), 'foo')
      dataset_2 = Linkage::Dataset.new(database_options_for('mysql'), 'foo')
      results_uri = database_options_for('sqlite')
      conf = dataset_1.link_with(dataset_2) do
        lhs[:foo].must == rhs[:foo]
        save_results_in(results_uri)
      end
      conf.score_set.create_tables!
      assert_include conf.score_set.database.tables, :original_groups
    end

    test "#create_tables! doesn't create original_groups table when decollation is needed" do
      database_for('sqlite') do |db|
        db.create_table!(:foo) { primary_key(:id); String(:foo) }
      end

      dataset = Linkage::Dataset.new(database_options_for('sqlite'), 'foo')
      results_uri = database_options_for('sqlite')
      conf = dataset.link_with(dataset) do
        lhs[:foo].must == rhs[:foo]
        save_results_in(results_uri)
      end
      conf.score_set.create_tables!
      assert_not_include conf.score_set.database.tables, :original_groups
    end

    test "#create_tables! doesn't create groups table when not needed" do
      database_for('sqlite') do |db|
        db.create_table!(:foo) { primary_key(:id); Integer(:foo) }
      end

      dataset = Linkage::Dataset.new(database_options_for('sqlite'), 'foo')
      results_uri = database_options_for('sqlite')
      conf = dataset.link_with(dataset) do
        lhs[:foo].must be_within(5).of(rhs[:foo])
        save_results_in(results_uri)
      end
      conf.score_set.create_tables!
      assert_not_include conf.score_set.database.tables, :groups
    end

    test "#create_tables! creates scores table when there are exhaustive expectations" do
      database_for('sqlite') do |db|
        db.create_table!(:foo) { primary_key(:id); Integer(:foo) }
      end

      dataset = Linkage::Dataset.new(database_options_for('sqlite'), 'foo')
      results_uri = database_options_for('sqlite')
      conf = dataset.link_with(dataset) do
        lhs[:foo].must be_within(5).of(rhs[:foo])
        save_results_in(results_uri)
      end
      conf.score_set.create_tables!
      assert_include conf.score_set.database.tables, :scores
    end

    test "#create_tables! doesn't create scores table when not needed" do
      database_for('sqlite') do |db|
        db.create_table!(:foo) { primary_key(:id); Integer(:foo) }
      end

      dataset = Linkage::Dataset.new(database_options_for('sqlite'), 'foo')
      results_uri = database_options_for('sqlite')
      conf = dataset.link_with(dataset) do
        lhs[:foo].must == rhs[:foo]
        save_results_in(results_uri)
      end
      conf.score_set.create_tables!
      assert_not_include conf.score_set.database.tables, :scores
    end
  end
end
