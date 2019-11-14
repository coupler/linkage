require 'helper'

class IntegrationTests::TestDatabaseResultSet < Test::Unit::TestCase
  def setup
    @dir = Dir.mktmpdir('linkage')
    @data_uri = database_options_for('sqlite', 'foo')
    @results_uri = database_options_for('sqlite', 'bar')
  end

  def teardown
    FileUtils.remove_entry_secure(@dir)
  end

  def data_database(options = {}, &block)
    Sequel.connect(@data_uri, options, &block)
  end

  def results_database(options = {}, &block)
    Sequel.connect(@results_uri, options, &block)
  end

  test "using a database for storing results" do
    data_database do |db|
      db.create_table(:foo) { primary_key(:id); Integer(:foo); Integer(:bar) }
      db[:foo].import([:id, :foo, :bar], Array.new(10) { |i| [i, i, i] })
    end

    ds = Linkage::Dataset.new(@data_uri, 'foo')
    result_set = Linkage::ResultSet['database'].new(@results_uri)
    conf = ds.link_with(ds, result_set) do |conf|
      conf.compare([:foo], [:bar], :equal)
      conf.algorithm = :mean
      conf.threshold = 1
    end
    runner = Linkage::Runner.new(conf)
    runner.execute

    results_database do |db|
      assert db.table_exists?(:scores)
      assert_equal 10, db[:scores].count
      db[:scores].order(:id_1, :id_2).each do |row|
        assert_equal row[:id_1], row[:id_2]
        assert_equal 1, row[:comparator_id]
        assert_kind_of Float, row[:score]
        assert_equal 1.0, row[:score]
      end

      assert db.table_exists?(:matches)
      assert_equal 10, db[:matches].count
      db[:matches].order(:id_1, :id_2).each do |row|
        assert_equal row[:id_1], row[:id_2]
        assert_kind_of Float, row[:score]
        assert_equal 1.0, row[:score]
      end
    end
  end
end
