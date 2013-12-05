module Linkage
  # Delegator around Sequel::Dataset with some extra functionality.
  class Dataset
    attr_reader :field_set, :table_name

    def initialize(*args)
      if args.length == 1
        @dataset = args[0]
        @db = @dataset.db
        @table_name = @dataset.first_source_table

        # Include the collation plugin if needed
        if !@db.kind_of?(Sequel::Collation)
          @db.extend(Sequel::Collation)
        end
      else
        uri, table, options = args
        options ||= {}

        @table_name = table.to_sym
        @db = Sequel.connect(uri, options)
        @db.extend(Sequel::Collation)
        @dataset = @db[@table_name]
      end
      @field_set = FieldSet.new(self)
    end

    def obj
      @dataset
    end

    def obj=(value)
      @dataset = value
    end

    # Setup a linkage with another dataset
    #
    # @return [Linkage::Configuration]
    def link_with(dataset, &block)
      conf = Configuration.new(self, dataset)
      conf.configure(&block)
      conf
    end

    def database_type
      @db.database_type
    end

    def schema
      @db.schema(@table_name)
    end

    protected

    def method_missing(name, *args, &block)
      result = @dataset.send(name, *args, &block)
      if result.kind_of?(Sequel::Dataset)
        new_object = clone
        new_object.obj = result
        result
      end
      result
    end
  end
end
