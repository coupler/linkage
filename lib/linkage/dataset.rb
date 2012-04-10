module Linkage
  class Dataset < Delegator
    attr_reader :field_set, :table_name

    def initialize(uri, table, options = {})
      @table_name = table.to_sym
      db = Sequel.connect(uri, options)
      ds = db[@table_name]
      super(ds)
      @field_set = FieldSet.new(db.schema(@table_name))
      @match_expressions = []
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

    def adapter_scheme
      @dataset.db.adapter_scheme
    end

    def match(*exprs)
      @add_match = exprs
      result = clone
      @add_match = nil
      result
    end

    def each_group(min = 2)
      #d = @dataset.group_and_count(*@match_expressions).having{count >= min}
      #p d
      #d.each do |row|
      @dataset.group_and_count(*@match_expressions).having{count >= min}.each do |row|
        yield Group.new(row)
      end
    end

    private

    def initialize_clone(obj)
      if @new_obj
        __setobj__(@new_obj)
        @new_obj = nil
      else
        __setobj__(obj.__getobj__.clone)
      end

      if @add_match
        @match_expressions.push(*@add_match)
        @add_match = nil
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
