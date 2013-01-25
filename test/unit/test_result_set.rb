require 'helper'

class TestResultSet < Test::Unit::TestCase
  def setup
    @config = stub('configuration', {
      :results_uri => 'foo://bar',
      :results_uri_options => {:blah => 'junk'},
      :decollation_needed? => true
    })
    @database = stub('database')
    Sequel.stubs(:connect).with('foo://bar', :blah => 'junk').returns(@database)
  end

  test "creating a result set with a configuration" do
    result_set = Linkage::ResultSet.new(@config)
  end

  test '#add_group creates two copies when decollation is needed' do
    result_set = Linkage::ResultSet.new(@config)

    group = stub('group', {
      :values => {:foo => 'bar '},
      :decollated_values => {:foo => 'BAR'}
    })

    groups_import_buffer = stub('groups import buffer')
    groups_dataset = stub('groups dataset')
    @database.stubs(:[]).with(:groups).returns(groups_dataset)
    Linkage::ImportBuffer.stubs(:new).with(groups_dataset, [:id, :foo]).
      returns(groups_import_buffer)

    original_groups_import_buffer = stub('original groups import buffer')
    original_groups_dataset = stub('original groups dataset')
    @database.stubs(:[]).with(:original_groups).returns(original_groups_dataset)
    Linkage::ImportBuffer.stubs(:new).with(original_groups_dataset, [:id, :foo]).
      returns(original_groups_import_buffer)

    groups_import_buffer.expects(:add).with([1, 'BAR'])
    original_groups_import_buffer.expects(:add).with([1, 'bar '])
    result_set.add_group(group)
  end

  test "#flush! flushes groups dataset" do
    result_set = Linkage::ResultSet.new(@config)

    group = stub('group', {
      :values => {:foo => 'bar '},
      :decollated_values => {:foo => 'BAR'}
    })

    groups_import_buffer = stub('groups import buffer')
    groups_dataset = stub('groups dataset')
    @database.stubs(:[]).with(:groups).returns(groups_dataset)
    Linkage::ImportBuffer.stubs(:new).with(groups_dataset, [:id, :foo]).
      returns(groups_import_buffer)

    original_groups_import_buffer = stub('original groups import buffer')
    original_groups_dataset = stub('original groups dataset')
    @database.stubs(:[]).with(:original_groups).returns(original_groups_dataset)
    Linkage::ImportBuffer.stubs(:new).with(original_groups_dataset, [:id, :foo]).
      returns(original_groups_import_buffer)

    groups_import_buffer.stubs(:add)
    original_groups_import_buffer.stubs(:add)
    result_set.add_group(group)

    groups_import_buffer.expects(:flush)
    original_groups_import_buffer.expects(:flush)
    result_set.flush!
  end

  test "#add_group doesn't create copies when decollation is not needed" do
    @config.stubs(:decollation_needed?).returns(false)
    result_set = Linkage::ResultSet.new(@config)

    group = stub('group', :values => {:foo => 'bar '})

    groups_import_buffer = stub('groups import buffer')
    groups_dataset = stub('groups dataset', :first_source_table => :groups, :db => @database)
    @database.stubs(:[]).with(:groups).returns(groups_dataset)
    Linkage::ImportBuffer.stubs(:new).with(groups_dataset, [:id, :foo]).
      returns(groups_import_buffer)

    original_groups_dataset = stub('original groups dataset', :first_source_table => :original_groups, :db => @database)
    @database.stubs(:[]).with(:original_groups).returns(original_groups_dataset)
    Linkage::ImportBuffer.expects(:new).with(original_groups_dataset, [:id, :foo]).never

    groups_import_buffer.expects(:add).with([1, 'bar '])
    result_set.add_group(group)
  end

  test "#add_score adds to score buffer" do
    result_set = Linkage::ResultSet.new(@config)
    scores_dataset = stub('scores dataset')
    @database.stubs(:[]).with(:scores).returns(scores_dataset)
    scores_import_buffer = stub('scores import buffer')
    Linkage::ImportBuffer.expects(:new).
      with(scores_dataset, [:comparator_id, :record_1_id, :record_2_id, :score]).
      returns(scores_import_buffer)
    scores_import_buffer.expects(:add).with([0, 1, 2, 123])
    scores_import_buffer.expects(:add).with([1, 1, 2, 456])
    result_set.add_score(0, 1, 2, 123)
    result_set.add_score(1, 1, 2, 456)
  end

  test "#flush! flushes score buffer" do
    result_set = Linkage::ResultSet.new(@config)
    scores_dataset = stub('scores dataset')
    @database.stubs(:[]).with(:scores).returns(scores_dataset)
    scores_import_buffer = stub('scores import buffer')
    Linkage::ImportBuffer.stubs(:new).
      with(scores_dataset, [:comparator_id, :record_1_id, :record_2_id, :score]).
      returns(scores_import_buffer)
    scores_import_buffer.stubs(:add)
    result_set.add_score(0, 1, 2, 123)

    scores_import_buffer.expects(:flush)
    result_set.flush!
  end

  test "#add_match adds to match buffer" do
    result_set = Linkage::ResultSet.new(@config)
    matches_dataset = stub('matches dataset')
    @database.stubs(:[]).with(:matches).returns(matches_dataset)
    matches_import_buffer = stub('matches import buffer')
    Linkage::ImportBuffer.expects(:new).
      with(matches_dataset, [:record_1_id, :record_2_id, :total_score]).
      returns(matches_import_buffer)
    matches_import_buffer.expects(:add).with([1, 2, 123])
    matches_import_buffer.expects(:add).with([2, 3, 456])
    result_set.add_match(1, 2, 123)
    result_set.add_match(2, 3, 456)
  end

  test "#flush! flushes match buffer" do
    result_set = Linkage::ResultSet.new(@config)
    matches_dataset = stub('matches dataset')
    @database.stubs(:[]).with(:matches).returns(matches_dataset)
    matches_import_buffer = stub('matches import buffer')
    Linkage::ImportBuffer.stubs(:new).
      with(matches_dataset, [:record_1_id, :record_2_id, :total_score]).
      returns(matches_import_buffer)
    matches_import_buffer.stubs(:add)
    result_set.add_match(1, 2, 123)

    matches_import_buffer.expects(:flush)
    result_set.flush!
  end
end
