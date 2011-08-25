module Linkage
  class Configuration
    class ExpectationWrapper
      def initialize(type, field, side, config)
        @type = type
        @field = field
        @side = side
        @config = config
      end

      def ==(other)
        @other = other
        add_expectation(:==)
      end

      private

      def add_expectation(operator)
        @config.add_expectation(@type, operator, @side, @field, @other.side, @other.field)
      end
    end

    class FieldWrapper
      attr_reader :field, :side
      def initialize(field, side, config)
        @field = field
        @side = side
        @config = config
      end

      def must
        ExpectationWrapper.new(:must, @field, @side, @config)
      end
    end

    class DatasetWrapper
      def initialize(side, config)
        @side = side
        @config = config
      end

      def [](field)
        FieldWrapper.new(field, @side, @config)
      end
    end

    class Expectation
      attr_reader :operator, :side_1, :field_1, :side_2, :field_2
      def initialize(operator, side_1, field_1, side_2, field_2)
        @operator = operator
        @side_1 = side_1
        @field_1 = field_1
        @side_2 = side_2
        @field_2 = field_2
      end
    end

    def initialize(dataset_1, dataset_2)
      @dataset_1 = dataset_1
      @dataset_2 = dataset_2
      @expectations = Hash.new { |h, k| h[k] = [] }
      @linkage_type = dataset_1 == dataset_2 ? :self : :dual
    end

    def lhs
      @lhs ||= DatasetWrapper.new(:lhs, self)
    end

    def rhs
      @rhs ||= DatasetWrapper.new(:rhs, self)
    end

    def add_expectation(type, operator, side_1, field_1, side_2, field_2)
      @expectations[type] << Expectation.new(operator, side_1, field_1, side_2, field_2)
    end

    def groups_table_schema
    end

    def inspect
      to_s
    end
  end
end
