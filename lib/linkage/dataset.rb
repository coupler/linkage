module Linkage
  # Delegator around Sequel::Dataset with some extra functionality.
  class Dataset
    attr_reader :field_set, :table_name

    def initialize(uri, table, options = {})
      @table_name = table.to_sym
      db = Sequel.connect(uri, options)
      db.extend(Sequel::Collation)
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

    def match(expr, aliaz = nil, cast = nil)
      clone(:match => {:expr => expr, :alias => aliaz, :cast => cast})
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
      @dataset.group_and_count(*match_expressions).having{count >= min}.each do |row|
        count = row.delete(:count)
        yield Group.new(row, {:count => count})
      end
    end

    def group_by_matches(raw = true)
      expr = raw ? raw_match_expressions : match_expressions
      group(*expr)
    end

    def dataset_for_group(group)
      filters = []
      group.values.each_pair do |key, value|
        # find a matched expression with this alias
        m = @_match.detect { |h| h[:alias] ? h[:alias] == key : h[:expr] == key }
        raise "this dataset isn't compatible with the given group" if !m
        filters << {m[:expr] => value}
      end
      filter(*filters)
    end

    private

    def _match(opts)
      if opts
        @_match += [opts]
      end
    end

    def raw_match_expressions
      @_match.collect { |m| m[:expr] }
    end

    def match_expressions
      @_match.collect do |m|
        expr = m[:expr]
        expr = expr.as(m[:alias]) if m[:alias]
        expr = expr.cast(m[:cast]) if m[:cast]
        expr
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
