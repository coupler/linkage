module Linkage
  # Wrapper for a Sequel dataset
  class Dataset
    def initialize(uri, table)
      @database = Sequel.connect(uri)
      @table = table.to_sym
      @dataset = @database[@table]
      @schema = @database.schema(@table)
    end

    def link_with(dataset, &block)
      conf = Configuration.new(self, dataset)
      conf.instance_eval(&block)
      conf
    end
  end
end
