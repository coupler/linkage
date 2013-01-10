require 'helper'

class UnitTests::TestImportBuffer < Test::Unit::TestCase
  test "basic usage" do
    database = stub('database')
    dataset = stub('dataset', :db => database)

    buf = Linkage::ImportBuffer.new(dataset, [:qux, :thud])
    buf.add([123, 456])
    buf.add(['test', 'junk'])

    database.expects(:synchronize).yields
    dataset.expects(:import).with([:qux, :thud], [[123, 456], ['test', 'junk']])
    buf.flush
  end

  test "flush performs a no-op when buffer is empty" do
    database = stub('database')
    dataset = stub('dataset', :db => database)
    dataset.expects(:import).never
    buf = Linkage::ImportBuffer.new(dataset, [:qux, :thud])
    buf.flush
  end

  test "auto-flush" do
    database = stub('database')
    dataset = stub('dataset', :db => database)
    headers = [:qux, :thud]
    limit = 3
    buf = Linkage::ImportBuffer.new(dataset, headers, limit)
    2.times { |i| buf.add([123, 456]) }

    database.expects(:synchronize).yields
    dataset.expects(:import).with([:qux, :thud], [[123, 456], [123, 456], ['test', 'junk']])
    buf.add(['test', 'junk'])
  end
end
