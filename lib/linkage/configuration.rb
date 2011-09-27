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
        @side = nil
        @forced_kind = nil
      end

      Linkage::Expectation::VALID_OPERATORS.each do |op|
        define_method(op) do |other|
          case other
          when FieldWrapper
            @other = other.field
            if other.side == @field.side
              @forced_kind = :filter
              @side = @field.side
            end
          else
            @other = other
            @side = @field.side
          end
          add_expectation(op)
        end
      end

      private

      def add_expectation(operator)
        klass = Expectation.get(@type)
        exp = klass.new(operator, @field.field, @other, @forced_kind)
        @config.add_expectation(exp, @side)
      end
    end

    # @private
    class FieldWrapper
      attr_reader :field, :side
      def initialize(field, side, config)
        @field = field
        @side = side
        @config = config
      end

      def must
        ExpectationWrapper.new(:must, self, @config)
      end
    end

    # @private
    class DatasetWrapper
      def initialize(dataset, side, config)
        @dataset = dataset
        @side = side
        @config = config
      end

      def [](field_name)
        field = @dataset.fields[field_name]
        if field.nil?
          raise ArgumentError, "The '#{field_name}' field doesn't exist for that dataset!"
        end
        FieldWrapper.new(field, @side, @config)
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
      @lhs_filters = []
      @rhs_filters = []
    end

    def lhs
      @lhs ||= DatasetWrapper.new(@dataset_1, :lhs, self)
    end

    def rhs
      @rhs ||= DatasetWrapper.new(@dataset_2, :rhs, self)
    end

    # @private
    def add_expectation(expectation, side = nil)
      # If the expectation created turns the linkage type from a self to a
      # cross, then the dataset gets a new id. This is so that
      # Expectation#apply does the right thing.

      @expectations << expectation
      if @linkage_type == :self
        cross = false

        case expectation.kind
        when :cross
          cross = true
        when :filter
          # If there different filters on both 'sides' of a self-linkage,
          # it turns into a cross linkage.
          these_filters, other_filters =
            case side
            when :lhs
              [@lhs_filters, @rhs_filters]
            when :rhs
              [@rhs_filters, @lhs_filters]
            end

          if !other_filters.empty? && !other_filters.include?(expectation)
            cross = true
          else
            these_filters << expectation
          end
        end

        if cross
          @linkage_type = :cross
          @dataset_2.send(:set_new_id)
        end
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
