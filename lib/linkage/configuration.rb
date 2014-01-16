module Linkage
  class Configuration
    attr_reader :dataset_1, :dataset_2, :comparators
    attr_accessor :record_cache_size

    def initialize(dataset_1, dataset_2 = nil)
      @dataset_1 = dataset_1
      @dataset_2 = dataset_2
      @comparators = []
      @record_cache_size = 10_000
    end

    def method_missing(name, *args, &block)
      klass = Comparator[name.to_s]
      if klass.nil?
        raise "unknown comparator: #{name}"
      end

      set_1 = args[0]
      if set_1.is_a?(Array)
        set_1 = fields_for(dataset_1, *set_1)
      else
        set_1 = fields_for(dataset_1, set_1).first
      end
      args[0] = set_1

      set_2 = args[1]
      if set_2.is_a?(Array)
        set_2 = fields_for(dataset_2, *set_2)
      else
        set_2 = fields_for(dataset_2, set_2).first
      end
      args[1] = set_2

      @comparators << klass.new(*args, &block)
    end

    protected

    def fields_for(dataset, *args)
      field_set = dataset.field_set
      args.collect { |name| field_set[name] }
    end
  end
end
