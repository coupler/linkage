module Linkage
  class ImportBuffer
    # @param [String] uri Sequel-style URI
    # @param [Symbol, String] table_name
    # @param [Array<Symbol>] headers List of fields you want to insert
    # @param [Hash] options Sequel.connect options
    # @param [Fixnum] limit Number of records to insert at a time
    def initialize(uri, table_name, headers, options = {}, limit = 1000)
      @uri = uri
      @table_name = table_name.to_sym
      @headers = headers
      @options = options
      @limit = limit
      @values = []
    end

    def add(values)
      @values << values
      if @values.length == @limit
        flush
      end
    end

    def flush
      return if @values.empty?
      database do |db|
        ds = db[@table_name]
        ds.import(@headers, @values)
        @values.clear
      end
    end

    private

    def database(&block)
      Sequel.connect(@uri, @options, &block)
    end
  end
end
