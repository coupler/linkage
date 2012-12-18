require 'helper'

module IntegrationTests
  class TestConfiguration < Test::Unit::TestCase
    test "linkage_type is self when the two datasets are the same" do
      database_for('sqlite') do |db|
        db.create_table(:foo) { primary_key(:id); String(:foo); String(:bar) }
      end

      dataset = Linkage::Dataset.new(database_options_for('sqlite'), "foo")
      conf = Linkage::Configuration.new(dataset, dataset)
      assert_equal :self, conf.linkage_type
    end

    test "linkage_type is dual when the two datasets are different" do
      database_for('sqlite') do |db|
        db.create_table(:foo) { primary_key(:id); String(:foo); String(:bar) }
        db.create_table(:bar) { primary_key(:id); String(:foo); String(:bar) }
      end

      dataset_1 = Linkage::Dataset.new(database_options_for('sqlite'), "foo")
      dataset_2 = Linkage::Dataset.new(database_options_for('sqlite'), "bar")
      conf = Linkage::Configuration.new(dataset_1, dataset_2)
      assert_equal :dual, conf.linkage_type
    end

    test "linkage_type is cross when there's different filters on both sides" do
      database_for('sqlite') do |db|
        db.create_table(:foo) { primary_key(:id); String(:foo); String(:bar) }
      end

      dataset = Linkage::Dataset.new(database_options_for('sqlite'), "foo")
      conf = Linkage::Configuration.new(dataset, dataset)
      conf.configure do
        lhs[:foo].must == "foo"
        rhs[:foo].must == "bar"
      end
      assert_equal :cross, conf.linkage_type
    end

    test "linkage_type is self when there's identical static filters on each side" do
      database_for('sqlite') do |db|
        db.create_table(:foo) { primary_key(:id); String(:foo); String(:bar) }
      end

      dataset = Linkage::Dataset.new(database_options_for('sqlite'), "foo")
      conf = Linkage::Configuration.new(dataset, dataset)
      conf.configure do
        lhs[:foo].must == "foo"
        rhs[:foo].must == "foo"
      end
      assert_equal :self, conf.linkage_type
    end

    test "static expectation" do
      database_for('sqlite') do |db|
        db.create_table(:foo) { primary_key(:id); String(:foo); String(:bar) }
      end

      dataset_1 = Linkage::Dataset.new(database_options_for('sqlite'), "foo")
      conf = Linkage::Configuration.new(dataset_1, dataset_1)
      conf.configure do
        lhs[:foo].must == "foo"
      end

      dataset_2, _ = conf.datasets_with_applied_simple_expectations
      assert_equal dataset_2.obj, dataset_1.filter(:foo => "foo").obj
    end

    test "complain if an invalid field is accessed" do
      database_for('sqlite') do |db|
        db.create_table(:foo) { primary_key(:id); String(:foo); String(:bar) }
      end

      dataset = Linkage::Dataset.new(database_options_for('sqlite'), "foo")
      conf = Linkage::Configuration.new(dataset, dataset)
      assert_raises(ArgumentError) do
        conf.configure do
          lhs[:foo].must == rhs[:non_existant_field]
        end
      end
    end

    operators = [:>, :<, :>=, :<=]
    operators.each do |operator|
      test "DSL #{operator} filter operator" do
        database_for('sqlite') do |db|
          db.create_table(:foo) { primary_key(:id); String(:foo); String(:bar) }
        end

        dataset_1 = Linkage::Dataset.new(database_options_for('sqlite'), "foo")
        conf = Linkage::Configuration.new(dataset_1, dataset_1)
        conf.configure do
          lhs[:foo].must.send(operator, 123)
        end

        expr = Sequel::SQL::BooleanExpression.new(operator, Sequel::SQL::Identifier.new(:foo), 123)
        dataset_2, _ = conf.datasets_with_applied_simple_expectations
        assert_equal dataset_2.obj, dataset_1.filter(expr).obj
      end
    end

    test "must_not expectation" do
      database_for('sqlite') do |db|
        db.create_table(:foo) { primary_key(:id); String(:foo); String(:bar) }
      end

      dataset_1 = Linkage::Dataset.new(database_options_for('sqlite'), "foo")
      conf = Linkage::Configuration.new(dataset_1, dataset_1)
      conf.configure do
        lhs[:foo].must_not == "foo"
      end

      dataset_2, _ = conf.datasets_with_applied_simple_expectations
      assert_equal dataset_2.obj, dataset_1.filter(~{:foo => "foo"}).obj
    end

    test "static database function" do
      database_for('sqlite') do |db|
        db.create_table(:foo) { primary_key(:id); String(:foo); String(:bar) }
      end

      dataset_1 = Linkage::Dataset.new(database_options_for('sqlite'), "foo")
      conf = Linkage::Configuration.new(dataset_1, dataset_1)
      conf.configure do
        lhs[:foo].must == trim("foo")
      end

      dataset_2, _ = conf.datasets_with_applied_simple_expectations
      assert_equal dataset_1.filter({:foo => :trim.sql_function("foo")}).obj, dataset_2.obj
    end

    test "save_results_in" do
      database_for('sqlite') do |db|
        db.create_table(:foo) { primary_key(:id); String(:foo); String(:bar) }
      end

      dataset_1 = Linkage::Dataset.new(database_options_for('sqlite'), "foo")
      conf = Linkage::Configuration.new(dataset_1, dataset_1)
      conf.configure do
        save_results_in("mysql://localhost/results", {:foo => 'bar'})
      end
      assert_equal "mysql://localhost/results", conf.results_uri
      assert_equal({:foo => 'bar'}, conf.results_uri_options)
    end

    test "case insensitive field names" do
      database_for('sqlite') do |db|
        db.create_table(:foo) { primary_key(:id); String(:foo); String(:bar) }
      end

      assert_nothing_raised do
        dataset = Linkage::Dataset.new(database_options_for('sqlite'), "foo")
        results_uri = database_options_for('sqlite')
        conf = dataset.link_with(dataset) do
          lhs[:Foo].must == rhs[:baR]
          save_results_in(results_uri)
        end
      end
    end

    test "decollation_needed? is false when the datasets and results dataset all have the same database and collations" do
      database_for('mysql') do |db|
        db.create_table!(:foo) { primary_key(:id); String(:foo, :collate => :latin1_swedish_ci) }
        db.create_table!(:bar) { primary_key(:id); String(:foo, :collate => :latin1_swedish_ci) }
      end

      dataset_1 = Linkage::Dataset.new(database_options_for('mysql'), 'foo')
      dataset_2 = Linkage::Dataset.new(database_options_for('mysql'), 'bar')
      conf = dataset_1.link_with(dataset_2) do
        lhs[:foo].must == rhs[:foo]
      end
      conf.results_uri = database_options_for('mysql')
      assert !conf.decollation_needed?
    end

    test "decollation_needed? is true when the datasets have different database types" do
      database_for('mysql') do |db|
        db.create_table!(:foo) { primary_key(:id); String(:foo) }
      end

      database_for('sqlite') do |db|
        db.create_table!(:foo) { primary_key(:id); String(:foo) }
      end

      dataset_1 = Linkage::Dataset.new(database_options_for('mysql'), 'foo')
      dataset_2 = Linkage::Dataset.new(database_options_for('sqlite'), 'foo')
      conf = dataset_1.link_with(dataset_2) do
        lhs[:foo].must == rhs[:foo]
      end
      conf.results_uri = database_options_for('mysql')
      assert conf.decollation_needed?
    end

    test "decollation_needed? is true when the result dataset has different database type than the datasets" do
      database_for('mysql') do |db|
        db.create_table!(:foo) { primary_key(:id); String(:foo) }
        db.create_table!(:bar) { primary_key(:id); String(:foo) }
      end

      dataset_1 = Linkage::Dataset.new(database_options_for('mysql'), 'foo')
      dataset_2 = Linkage::Dataset.new(database_options_for('mysql'), 'bar')
      conf = dataset_1.link_with(dataset_2) do
        lhs[:foo].must == rhs[:foo]
      end
      conf.results_uri = database_options_for('sqlite')
      assert conf.decollation_needed?
    end

    test "decollation_needed? is false when not comparing string columns" do
      database_for('mysql') do |db|
        db.create_table!(:foo) { primary_key(:id); Fixnum(:foo) }
      end

      database_for('sqlite') do |db|
        db.create_table!(:foo) { primary_key(:id); Fixnum(:foo) }
      end

      dataset_1 = Linkage::Dataset.new(database_options_for('mysql'), 'foo')
      dataset_2 = Linkage::Dataset.new(database_options_for('sqlite'), 'foo')
      conf = dataset_1.link_with(dataset_2) do
        lhs[:foo].must == rhs[:foo]
      end
      conf.results_uri = database_options_for('mysql')
      assert !conf.decollation_needed?
    end

    test "creating comparator expectation for within" do
      database_for('mysql') do |db|
        db.create_table!(:foo) { primary_key(:id); Integer(:foo) }
      end
      dataset = Linkage::Dataset.new(database_options_for('mysql'), 'foo')

      conf = dataset.link_with(dataset) do
        lhs[:foo].must be_within(5).of(rhs[:foo])
      end
    end
  end
end
