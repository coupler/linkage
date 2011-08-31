module Linkage
  # Internal class used to configure linkages. See {Dataset#link_with}
  # for more information.
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

    include Utils

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
      schema = []

      # add record_id
      schema << merge_fields(
        @dataset_1.primary_key[1],
        @dataset_2.primary_key[1]
      ).update(:name => :record_id)

      # add group_id
      schema << {:name => :group_id, :type => Integer, :opts => {}}

      if @expectations.has_key?(:must)
        @expectations[:must].each do |exp|
          field_1 = @dataset_1.schema.assoc(exp.field_1)[1]
          field_2 = @dataset_2.schema.assoc(exp.field_2)[1]
          info = merge_fields(field_1, field_2)
          schema << info.update(:name => exp.field_1)
        end
      end

      schema
    end

    def inspect
      to_s
    end
  end
end
