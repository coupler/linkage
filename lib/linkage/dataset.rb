module Linkage
  # Wrapper for a Sequel dataset
  class Dataset
    # @return [Array] Schema information about the dataset's primary key
    attr_reader :primary_key

    # @return [Array] Schema information for this dataset
    attr_reader :schema

    # @param [String] uri Sequel-style database URI
    # @param [String] table Database table name
    # @see http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html Sequel: Connecting to a database
    def initialize(uri, table)
      @database = Sequel.connect(uri)
      @table = table.to_sym
      @dataset = @database[@table]
      @schema = @database.schema(@table)
      create_fields
    end

    # Setup a linkage with another dataset
    #
    # @return [Linkage::Configuration]
    def link_with(dataset, &block)
      conf = Configuration.new(self, dataset)
      conf.instance_eval(&block)
      conf
    end

    private

    def create_fields
      @fields = []
      @schema.each do |(name, column_schema)|
        f = Field.new(name, column_schema)
        f.dataset = self
        @fields << f

        if @primary_key.nil? && column_schema[:primary_key]
          @primary_key = f
        end
      end
    end
  end
end
