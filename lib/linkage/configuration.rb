module Linkage
  class Configuration
    class Expectation
      def initialize(type, field, config)
        @type = type
        @field = field
        @config = config
      end

      def ==(other)
        @other = other
        self.freeze
        @config.add_expectation(self)
      end
    end

    class FieldWrapper
      def initialize(field, dataset, config)
        @field = field
        @dataset = dataset
        @config = config
      end

      def must
        Expectation.new(:must, self, @config)
      end
    end

    class DatasetWrapper
      def initialize(dataset, config)
        @dataset = dataset
        @config = config
      end

      def [](field)
        FieldWrapper.new(field, self, @config)
      end
    end

    def initialize(dataset_1, dataset_2)
      @dataset_1 = dataset_1
      @dataset_2 = dataset_2
      @expectations = []
    end

    def lhs
      @lhs ||= DatasetWrapper.new(@dataset_1, self)
    end

    def rhs
      @rhs ||= DatasetWrapper.new(@dataset_2, self)
    end

    def add_expectation(expectation)
      @expectations << expectation
    end

    def inspect
      to_s
    end
  end
end
