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
end
