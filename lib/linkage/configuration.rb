module Linkage
  # {Configuration} is used to configure linkages. When you call
  # {Dataset#link_with}, the block you supply gets called in the context of
  # an instance of {Configuration}.
  #
  # @example
  #   dataset_1 = Linkage::Dataset.new("mysql://example.com/database_name", "table_1")
  #   dataset_2 = Linkage::Dataset.new("mysql://example.com/database_name", "table_2")
  #   dataset_1.link_with(dataset_2) do
  #     # this gets run inside of a Configuration instance
  #   end
  #
  # @see Dataset#link_with
  class Configuration
    # @private
    class ExpectationWrapper
      def initialize(type, field, config)
        @type = type
        @field = field
        @config = config
      end

      def ==(other)
        @other =
          case other
          when FieldWrapper
            other.field
          else
            other
          end
        add_expectation(:==)
      end

      private

      def add_expectation(operator)
        klass = Expectation.get(@type)
        @config.add_expectation(klass.new(operator, @field.field, @other))
      end
    end

    # @private
    class FieldWrapper
      attr_reader :field
      def initialize(field, config)
        @field = field
        @config = config
      end

      def must
        ExpectationWrapper.new(:must, self, @config)
      end
    end

    # @private
    class DatasetWrapper
      def initialize(dataset, config)
        @dataset = dataset
        @config = config
      end

      def [](field_name)
        FieldWrapper.new(@dataset.fields[field_name], @config)
      end
    end

    include Utils

    # @return [Symbol] :self, :dual, or :cross
    attr_reader :linkage_type

    # @return [Array<Linkage::Expectation>]
    attr_reader :expectations

    # @return [Linkage::Dataset]
    attr_reader :dataset_1

    # @return [Linkage::Dataset]
    attr_reader :dataset_2

    def initialize(dataset_1, dataset_2)
      @dataset_1 = dataset_1.clone
      @dataset_2 = dataset_2.clone
      @expectations = []
      @linkage_type = dataset_1 == dataset_2 ? :self : :dual
    end

    def lhs
      @lhs ||= DatasetWrapper.new(@dataset_1, self)
    end

    def rhs
      @rhs ||= DatasetWrapper.new(@dataset_2, self)
    end

    # @private
    def add_expectation(expectation)
      # If the expectation created turns the linkage type from a self to a
      # cross, then the dataset gets a new id. This is so that
      # Expectation#apply does the right thing.

      @expectations << expectation
      if @linkage_type == :self && expectation.kind == :cross
        @linkage_type = :cross
        @dataset_2.send(:set_new_id)
      end
    end

    # @private
    def groups_table_schema
      schema = []

      # add id
      schema << [:id, Integer, :primary_key => true]

      # add values
      @expectations.each do |exp|
        next  if exp.kind == :filter

        merged_type = exp.merged_field.ruby_type
        schema << [exp.name, merged_type[:type], merged_type[:opts] || {}]
      end

      schema
    end

    # @private
    def inspect
      to_s
    end
  end
end
