module Linkage
  class Expectation
    def self.get(type)
      TYPES[type]
    end

    attr_reader :operator, :field_1, :field_2

    # @param [Symbol] operator Currently, only :==
    # @param [Linkage::Field, Object] field_1
    # @param [Linkage::Field, Object] field_2
    def initialize(operator, field_1, field_2)
      @operator = operator
      @field_1 = field_1
      @field_2 = field_2

      if !(@field_1.is_a?(Field) || @field_2.is_a?(Field))
        raise ArgumentError, "You must have at least one Linkage::Field"
      end

      if kind == :filter
        if @field_1.is_a?(Field)
          @filter_field = @field_1
          @filter_value = @field_2
        else
          @filter_field = @field_2
          @filter_value = @field_1
        end
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

    # Apply changes to a dataset based on the expectation, such as calling
    # {Dataset#add_order}, {Dataset#add_select}, and {Dataset#add_filter}
    # with the appropriate arguments.
    def apply_to(dataset)
      if kind == :filter
        if @filter_field.belongs_to?(dataset, true)
          dataset.add_filter(@filter_field, @operator, @filter_value)
        end
      else
        as = name != @field_1.name ? name : nil
        if @field_1.belongs_to?(dataset, kind == :cross)
          dataset.add_order(@field_1)
          dataset.add_select(@field_1, as)
        end
        if @field_2.belongs_to?(dataset, kind == :cross)
          dataset.add_order(@field_2)
          dataset.add_select(@field_2, as)
        end
      end
    end
  end

  class MustExpectation < Expectation
  end

  Expectation::TYPES = { :must => MustExpectation }
end
