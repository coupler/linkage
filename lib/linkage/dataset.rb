module Linkage
  # Delegator around Sequel::Dataset with some extra functionality.
  class Dataset
    attr_reader :field_set, :table_name

    def initialize(*args)
      if args.length == 0 || args.length > 3
        raise ArgumentError, "wrong number of arguments (#{args.length} for 1..3)"
      end

      if args.length == 1
        unless args[0].kind_of?(Sequel::Dataset)
          raise ArgumentError, "expected Sequel::Dataset, got #{args[0].class}"
        end

        @dataset = args[0]
        @db = @dataset.db
        @table_name = @dataset.first_source_table
      elsif args.length == 2 && args[0].kind_of?(Sequel::Database)
        @db = args[0]
        @table_name = args[1].to_sym
        @dataset = @db[@table_name]
      else
        uri, table_name, options = args
        options ||= {}

        @db = Sequel.connect(uri, options)
        @table_name = table_name.to_sym
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
    def link_with(dataset, score_set, match_set)
      other = dataset.eql?(self) ? nil : dataset
      conf = Configuration.new(self, other, score_set, match_set)
      if block_given?
        yield conf
      end
      conf
    end

    def database_type
      @db.database_type
    end

    def schema
      @db.schema(@table_name)
    end

    def primary_key
      @field_set.primary_key
    end

    protected

    def method_missing(name, *args, &block)
      result = @dataset.send(name, *args, &block)
      if result.kind_of?(Sequel::Dataset)
        new_object = clone
        new_object.obj = result
        new_object
      else
        result
      end
    end
  end
end
