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
      @comparators << klass.new(*args, &block)
    end
  end
end
