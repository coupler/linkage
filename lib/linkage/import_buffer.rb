module Linkage
  class ImportBuffer
    def initialize(uri, table_name, headers, limit = 1000)
      @uri = uri
      @table_name = table_name.to_sym
      @headers = headers
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
        begin
          ds.import(@headers, @values)
        rescue Sequel::Error
          pp @headers
          pp @values
          raise
        end
        @values.clear
      end
    end

    private

    def database(&block)
      Sequel.connect(@uri, &block)
    end
  end
end
