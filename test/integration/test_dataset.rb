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
end
