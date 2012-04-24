module Linkage
  # Delegator around Sequel::Dataset with some extra functionality.
  class Dataset
    attr_reader :field_set, :table_name
    attr_accessor :_match

    def initialize(uri, table, options = {})
      @table_name = table.to_sym
      db = Sequel.connect(uri, options)
      @dataset = db[@table_name]
      @field_set = FieldSet.new(db.schema(@table_name))
      @_match = []
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

    def adapter_scheme
      @dataset.db.adapter_scheme
    end

    def match(*exprs)
      clone(:match => exprs)
    end

    def clone(new_opts={})
      new_opts = new_opts.dup
      new_obj = new_opts.delete(:new_obj)

      match = new_opts.delete(:match)
      result = super()
      result.send(:_match, match)

      if new_obj
        result.obj = new_obj
      else
        result.obj = obj.clone(new_opts)
      end
      result
    end

    def each_group(min = 2)
      #d = @dataset.group_and_count(*@_match).having{count >= min}
      #p d
      #d.each do |row|
      @dataset.group_and_count(*@_match).having{count >= min}.each do |row|
        yield Group.new(row)
      end
    end

    def group_by_matches
      group(*@_match)
    end

    private

    def _match(exprs)
      if exprs
        @_match += exprs
      end
    end

    def method_missing(name, *args, &block)
      result = @dataset.send(name, *args, &block)
      if result.kind_of?(Sequel::Dataset)
        new_obj = result
        result = clone(:new_obj => result)
      end
      result
    end
  end
end
