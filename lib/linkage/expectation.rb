module Linkage
  class Expectation
    VALID_OPERATORS = [:==, :>, :<, :>=, :<=, :'!=']

    def self.get(type)
      TYPES[type]
    end

    attr_reader :operator, :field_1, :field_2

    # @param [Symbol] operator Currently, only :==
    # @param [Linkage::Field, Linkage::Function, Object] field_1
    # @param [Linkage::Field, Linkage::Function, Object] field_2
    # @param [Symbol] force_kind Manually set type of expectation (useful for
    #   a filter between two fields)
    def initialize(operator, field_1, field_2, force_kind = nil)
      if !((field_1.kind_of?(Data) && !field_1.static?) || (field_2.kind_of?(Data) && !field_2.static?))
        raise ArgumentError, "You must have at least one data source (Linkage::Field or Linkage::Function)"
      end

      if !VALID_OPERATORS.include?(operator)
        raise ArgumentError, "Invalid operator: #{operator.inspect}"
      end

      @operator = operator
      @field_1 = field_1
      @field_2 = field_2
      @kind = force_kind

      if kind == :filter
        if @field_1.is_a?(Field)
          @filter_field = @field_1
          @filter_value = @field_2
        else
          @filter_field = @field_2
          @filter_value = @field_1
        end
      elsif @operator != :==
        raise ArgumentError, "Inequality operators are not allowed for non-filter expectations"
      end
    end

    def ==(other)
      if other.is_a?(Expectation)
        @operator == other.operator && @field_1 == other.field_1 &&
          @field_2 == other.field_2
      else
        super
      end
    end

    # @return [Symbol] :self, :dual, :cross, or :filter
    def kind
      @kind ||=
        if !(@field_1.is_a?(Field) && @field_2.is_a?(Field))
          :filter
        elsif @field_1 == @field_2
          :self
        elsif @field_1.dataset == @field_2.dataset
          :cross
        else
          :dual
        end
    end

    # @return [Symbol] name of the merged field type
    def name
      merged_field.name
    end

    # @return [Linkage::Field] result of Field#merge between the two fields
    def merged_field
      @merged_field ||= @field_1.merge(@field_2)
    end

    # @return [Boolean] Whether or not this expectation involves a field in
    #   the given dataset (Only useful for :filter expressions)
    def applies_to?(dataset)
      if kind == :filter
        @filter_field.belongs_to?(dataset)
      else
        @field_1.belongs_to?(dataset) || @field_2.belongs_to?(dataset)
      end
    end

    # Apply changes to a dataset based on the expectation, such as calling
    # {Dataset#add_order}, {Dataset#add_select}, and {Dataset#add_filter}
    # with the appropriate arguments.
    def apply_to(dataset)
      case kind
      when :filter
        if @filter_field.belongs_to?(dataset)
          dataset.add_filter(@filter_field, @operator, @filter_value)
        end
      else
        as =
          if kind == :self
            nil
          else
            name != @field_1.name ? name : nil
          end

        if @field_1.belongs_to?(dataset)
          dataset.add_order(@field_1)
          dataset.add_select(@field_1, as)
        end
        if @field_2.belongs_to?(dataset)
          dataset.add_order(@field_2)
          dataset.add_select(@field_2, as)
        end
      end
    end
  end

  class MustExpectation < Expectation
  end

  class MustNotExpectation < Expectation
    OPERATOR_OPPOSITES = {
      :==   => :'!=',
      :'!=' => :==,
      :>    => :<=,
      :<=   => :>,
      :<    => :>=,
      :>=   => :<
    }

    # Same as Expectation, except it negates the operator.
    def initialize(operator, field_1, field_2, force_kind = nil)
      super(OPERATOR_OPPOSITES[operator], field_1, field_2, force_kind)
    end
  end

  Expectation::TYPES = {
    :must => MustExpectation,
    :must_not => MustNotExpectation
  }
end
