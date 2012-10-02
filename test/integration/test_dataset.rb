require 'helper'

class IntegrationTests::TestDataset < Test::Unit::TestCase
  def setup
    @tmpdir = Dir.mktmpdir('linkage')
    @tmpuri = "sqlite://" + File.join(@tmpdir, "foo")
  end

  def database(&block)
    Sequel.connect(@tmpuri, &block)
  end

  def teardown
    FileUtils.remove_entry_secure(@tmpdir)
  end

  test "methods that clone the dataset" do
    database do |db|
      db.create_table(:foo) do
        primary_key :id
        String :bar
      end
    end
    ds_1 = Linkage::Dataset.new(@tmpuri, "foo")
    ds_2 = ds_1.filter(:foo => 'bar')
    assert_instance_of Linkage::Dataset, ds_2
    assert_equal ds_2.field_set, ds_1.field_set
    assert_match /`foo` = 'bar'/, ds_2.sql
  end

  test "each_group" do
    database do |db|
      db.create_table(:foo) do
        primary_key :id
        String :bar
      end
      db[:foo].import([:id, :bar], [[1, 'foo'], [2, 'foo'], [3, 'bar'], [4, 'baz']])
    end

    ds = Linkage::Dataset.new(@tmpuri, "foo")
    ds = ds.match(ds.field_set[:bar])
    ds.each_group do |group|
      assert_equal({:bar => "foo"}, group.values)
      assert_equal(2, group.count)
    end

    groups = []
    ds.each_group(1) do |group|
      groups << group
    end
    assert_equal 3, groups.length
  end

  test "each_group with filters" do
    database do |db|
      db.create_table(:foo) do
        primary_key :id
        String :bar
        Integer :baz
      end
      db[:foo].import([:id, :bar, :baz], [[1, 'foo', 1], [2, 'foo', 2], [3, 'bar', 3], [4, 'baz', 4]])
    end

    ds = Linkage::Dataset.new(@tmpuri, "foo")
    ds = ds.match(ds.field_set[:bar])
    ds = ds.filter { baz >= 3 }
    groups = []
    ds.each_group(1) do |group|
      groups << group
    end
    assert_equal 2, groups.length
  end
end
