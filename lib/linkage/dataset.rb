module Linkage
  # Wrapper for a Sequel dataset
  class Dataset
    # @return [Array] Schema information about the dataset's primary key
    attr_reader :primary_key

    # @param [String] uri Sequel-style database URI
    # @param [String] table Database table name
    # @see http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html Sequel: Connecting to a database
    def initialize(uri, table)
      @database = Sequel.connect(uri)
      @table = table.to_sym
      @dataset = @database[@table]
      @schema = @database.schema(@table)
      @primary_key = @schema.find { |f| f[1][:primary_key] }
    end

    # Setup a linkage with another dataset.
    #
    # @return [Linkage::Configuration]
    def link_with(dataset, &block)
      conf = Configuration.new(self, dataset)
      conf.instance_eval(&block)
      conf
    end
  end
end
