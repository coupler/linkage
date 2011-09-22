require 'helper'

class UnitTests::TestImportBuffer < Test::Unit::TestCase
  test "basic usage" do
    buf = Linkage::ImportBuffer.new('foo:/bar/db', 'baz_table', [:qux, :thud])
    buf.add([123, 456])
    buf.add(['test', 'junk'])

    database = mock('database')
    Sequel.expects(:connect).with('foo:/bar/db').yields(database)
    dataset = mock('dataset')
    database.expects(:[]).with(:baz_table).returns(dataset)
    dataset.expects(:import).with([:qux, :thud], [[123, 456], ['test', 'junk']])
    buf.flush
  end

  test "flush performs a no-op when buffer is empty" do
    Sequel.expects(:connect).never
    buf = Linkage::ImportBuffer.new('foo:/bar/db', 'baz_table', [:qux, :thud])
    buf.flush
  end

  test "auto-flush" do
    uri = 'foo:/bar/db'
    table = 'baz_table'
    headers = [:qux, :thud]
    limit = 3
    buf = Linkage::ImportBuffer.new(uri, table, headers, limit)
    2.times { |i| buf.add([123, 456]) }

    database = mock('database')
    Sequel.expects(:connect).with('foo:/bar/db').yields(database)
    dataset = mock('dataset')
    database.expects(:[]).with(:baz_table).returns(dataset)
    dataset.expects(:import).with([:qux, :thud], [[123, 456], [123, 456], ['test', 'junk']])
    buf.add(['test', 'junk'])
  end
end
