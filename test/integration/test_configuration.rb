require 'helper'

module IntegrationTests
  class TestConfiguration < Test::Unit::TestCase
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

    test "linkage_type is self when the two datasets are the same" do
      database do |db|
        db.create_table(:foo) { primary_key(:id); String(:foo); String(:bar) }
      end

      dataset = Linkage::Dataset.new(@tmpuri, "foo")
      conf = Linkage::Configuration.new(dataset, dataset)
      assert_equal :self, conf.linkage_type
    end

    test "linkage_type is dual when the two datasets are different" do
      database do |db|
        db.create_table(:foo) { primary_key(:id); String(:foo); String(:bar) }
        db.create_table(:bar) { primary_key(:id); String(:foo); String(:bar) }
      end

      dataset_1 = Linkage::Dataset.new(@tmpuri, "foo")
      dataset_2 = Linkage::Dataset.new(@tmpuri, "bar")
      conf = Linkage::Configuration.new(dataset_1, dataset_2)
      assert_equal :dual, conf.linkage_type
    end

    test "linkage_type is cross when there's different filters on both sides" do
      database do |db|
        db.create_table(:foo) { primary_key(:id); String(:foo); String(:bar) }
      end

      dataset = Linkage::Dataset.new(@tmpuri, "foo")
      conf = Linkage::Configuration.new(dataset, dataset)
      conf.configure do
        lhs[:foo].must == "foo"
        rhs[:foo].must == "bar"
      end
      assert_equal :cross, conf.linkage_type
    end

    test "linkage_type is self when there's identical static filters on each side" do
      database do |db|
        db.create_table(:foo) { primary_key(:id); String(:foo); String(:bar) }
      end

      dataset = Linkage::Dataset.new(@tmpuri, "foo")
      conf = Linkage::Configuration.new(dataset, dataset)
      conf.configure do
        lhs[:foo].must == "foo"
        rhs[:foo].must == "foo"
      end
      assert_equal :self, conf.linkage_type
    end

    test "static expectation" do
      database do |db|
        db.create_table(:foo) { primary_key(:id); String(:foo); String(:bar) }
      end

      dataset_1 = Linkage::Dataset.new(@tmpuri, "foo")
      conf = Linkage::Configuration.new(dataset_1, dataset_1)
      conf.configure do
        lhs[:foo].must == "foo"
      end

      dataset_2, _ = conf.datasets_with_applied_expectations
      assert_equal dataset_2.obj, dataset_1.filter(:foo => "foo").obj
    end

    test "complain if an invalid field is accessed" do
      database do |db|
        db.create_table(:foo) { primary_key(:id); String(:foo); String(:bar) }
      end

      dataset = Linkage::Dataset.new(@tmpuri, "foo")
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
        database do |db|
          db.create_table(:foo) { primary_key(:id); String(:foo); String(:bar) }
        end

        dataset_1 = Linkage::Dataset.new(@tmpuri, "foo")
        conf = Linkage::Configuration.new(dataset_1, dataset_1)
        conf.configure do
          lhs[:foo].must.send(operator, 123)
        end

        expr = Sequel::SQL::BooleanExpression.new(operator, Sequel::SQL::Identifier.new(:foo), 123)
        dataset_2, _ = conf.datasets_with_applied_expectations
        assert_equal dataset_2.obj, dataset_1.filter(expr).obj
      end
    end

    test "must_not expectation" do
      database do |db|
        db.create_table(:foo) { primary_key(:id); String(:foo); String(:bar) }
      end

      dataset_1 = Linkage::Dataset.new(@tmpuri, "foo")
      conf = Linkage::Configuration.new(dataset_1, dataset_1)
      conf.configure do
        lhs[:foo].must_not == "foo"
      end

      dataset_2, _ = conf.datasets_with_applied_expectations
      assert_equal dataset_2.obj, dataset_1.filter(~{:foo => "foo"}).obj
    end

    test "static database function" do
      database do |db|
        db.create_table(:foo) { primary_key(:id); String(:foo); String(:bar) }
      end

      dataset_1 = Linkage::Dataset.new(@tmpuri, "foo")
      conf = Linkage::Configuration.new(dataset_1, dataset_1)
      conf.configure do
        lhs[:foo].must == trim("foo")
      end

      dataset_2, _ = conf.datasets_with_applied_expectations
      assert_equal dataset_1.filter({:foo => :trim.sql_function("foo")}).obj, dataset_2.obj
    end

    test "save_results_in" do
      database do |db|
        db.create_table(:foo) { primary_key(:id); String(:foo); String(:bar) }
      end

      dataset_1 = Linkage::Dataset.new(@tmpuri, "foo")
      conf = Linkage::Configuration.new(dataset_1, dataset_1)
      conf.configure do
        save_results_in("mysql://localhost/results", {:foo => 'bar'})
      end
      assert_equal "mysql://localhost/results", conf.results_uri
      assert_equal({:foo => 'bar'}, conf.results_uri_options)
    end

    test "case insensitive field names" do
      database do |db|
        db.create_table(:foo) { primary_key(:id); String(:foo); String(:bar) }
      end

      assert_nothing_raised do
        dataset = Linkage::Dataset.new(@tmpuri, "foo")
        tmpuri = @tmpuri
        conf = dataset.link_with(dataset) do
          lhs[:Foo].must == rhs[:baR]
          save_results_in(tmpuri)
        end
      end
    end
  end
end
