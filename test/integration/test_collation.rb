require 'helper'

module IntegrationTests
  class TestCollation < Test::Unit::TestCase
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

    test "comparing strings exactly in MySQL" do
      options = database_options_for('mysql')
      database_for('mysql') do |db|
        db.create_table!(:foo) do
          primary_key :id
          String :foo
          String :bar
        end
        db[:foo].import([:foo, :bar], [
          ["Foo", "foo"],
          ["bar", "bar "],
        ])
      end
      dataset = Linkage::Dataset.new(options, :foo)
      tmpuri = @tmpuri
      conf = dataset.link_with(dataset) do
        (lhs[:foo].must == rhs[:bar]).exactly
        save_results_in(tmpuri)
      end
      runner = Linkage::SingleThreadedRunner.new(conf)
      runner.execute

      database do |db|
        assert_equal 0, db[:groups].count
      end
    end
  end
end
