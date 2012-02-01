module Linkage
  class Dataset < Delegator
    attr_reader :field_set

    def initialize(uri, table, options = {})
      table_name = table.to_sym
      db = Sequel.connect(uri, options)
      ds = db[table_name]
      super(ds)
      @field_set = FieldSet.new(db.schema(table_name))
    end

    def __setobj__(obj); @dataset = obj; end
    def __getobj__; @dataset; end

    # Setup a linkage with another dataset
    #
    # @return [Linkage::Configuration]
    def link_with(dataset, &block)
      conf = Configuration.new(self, dataset)
      conf.configure(&block)
      conf
    end

    def initialize_clone(obj)
      new_obj = obj.instance_variable_get(:@new_obj)
      if new_obj
        __setobj__(new_obj)
      else
        super
      end
    end

    def method_missing(name, *args, &block)
      result = super
      if result.kind_of?(Sequel::Dataset)
        @new_obj = result
        result = clone
        @new_obj = nil
      end
      result
    end
  end
end
