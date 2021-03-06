require 'helper'

class IntegrationTests::TestSelfLinkage < Test::Unit::TestCase
  def setup
    @tmpdir = Dir.mktmpdir('linkage')
    @tmpuri = database_options_for('sqlite')
  end

  def database(&block)
    Sequel.connect(@tmpuri, &block)
  end

  def teardown
    FileUtils.remove_entry_secure(@tmpdir)
  end

  test "one-field equality" do
    # insert the test data
    database do |db|
      db.create_table(:foo) { primary_key(:id); String(:ssn) }
      db[:foo].import([:id, :ssn],
        Array.new(100) { |i| [i, "12345678#{i%10}"] })
    end

    result_set = Linkage::ResultSet['csv'].new(@tmpdir)
    dataset = Linkage::Dataset.new(@tmpuri, "foo", :single_threaded => true)
    conf = dataset.link_with(dataset, result_set) do |conf|
      conf.compare([:ssn], [:ssn], :equal)
      conf.algorithm = :mean
      conf.threshold = 1.0
    end

    runner = Linkage::Runner.new(conf)
    runner.execute

    score_csv = CSV.read(File.join(@tmpdir, 'scores.csv'), :headers => true)
    assert_equal 450, score_csv.length
    score_csv.each do |row|
      assert_equal row['id_1'].to_i % 10, row['id_2'].to_i % 10
    end

    match_csv = CSV.read(File.join(@tmpdir, 'matches.csv'), :headers => true)
    assert_equal 450, match_csv.length
    match_csv.each do |row|
      assert_equal row['id_1'].to_i % 10, row['id_2'].to_i % 10
    end
  end

  test "two-field equality" do
    # insert the test data
    database do |db|
      db.create_table(:foo) { primary_key(:id); String(:ssn); Date(:dob) }
      db[:foo].import([:id, :ssn, :dob],
        Array.new(100) { |i| [i, "12345678#{i%10}", Date.civil(1985, 1, (i % 20) + 1)] })
    end

    result_set = Linkage::ResultSet['csv'].new(@tmpdir)
    dataset = Linkage::Dataset.new(@tmpuri, "foo", :single_threaded => true)
    conf = dataset.link_with(dataset, result_set) do |conf|
      conf.compare([:ssn, :dob], [:ssn, :dob], :equal)
    end

    runner = Linkage::Runner.new(conf)
    runner.execute

    score_csv = CSV.read(File.join(@tmpdir, 'scores.csv'), :headers => true)
    assert_equal 200, score_csv.length
    score_csv.each do |row|
      id_1 = row['id_1'].to_i
      id_2 = row['id_2'].to_i
      assert id_1 % 10 == id_2 % 10
      assert id_1 % 20 == id_2 % 20
    end

    match_csv = CSV.read(File.join(@tmpdir, 'matches.csv'), :headers => true)
    assert_equal 200, match_csv.length
    match_csv.each do |row|
      id_1 = row['id_1'].to_i
      id_2 = row['id_2'].to_i
      assert id_1 % 10 == id_2 % 10
      assert id_1 % 20 == id_2 % 20
    end
  end

  test "one-field equality with blocking" do
    # insert the test data
    database do |db|
      db.create_table(:foo) { primary_key(:id); String(:ssn); Integer(:mod_5) }
      db[:foo].import([:id, :ssn, :mod_5],
        Array.new(100) { |i| [i, "12345678#{i%10}", i % 5] })
    end

    result_set = Linkage::ResultSet['csv'].new(@tmpdir)
    dataset = Linkage::Dataset.new(@tmpuri, "foo", :single_threaded => true)
    dataset = dataset.filter(:mod_5 => 3)
    conf = dataset.link_with(dataset, result_set) do |conf|
      conf.compare([:ssn], [:ssn], :equal)
    end

    runner = Linkage::Runner.new(conf)
    runner.execute

    score_csv = CSV.read(File.join(@tmpdir, 'scores.csv'), :headers => true)
    assert_equal 90, score_csv.length
    score_csv.each do |row|
      id_1 = row['id_1'].to_i
      id_2 = row['id_2'].to_i
      assert id_1 % 10 == id_2 % 10
      assert id_1 % 5 == id_2 % 5
    end

    match_csv = CSV.read(File.join(@tmpdir, 'matches.csv'), :headers => true)
    assert_equal 90, match_csv.length
    match_csv.each do |row|
      id_1 = row['id_1'].to_i
      id_2 = row['id_2'].to_i
      assert id_1 % 10 == id_2 % 10
      assert id_1 % 5 == id_2 % 5
    end
  end
end
