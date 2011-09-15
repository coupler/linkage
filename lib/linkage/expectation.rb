module Linkage
  class Expectation
    def self.get(type)
      TYPES[type]
    end

    attr_reader :operator, :field_1, :field_2

    def initialize(operator, field_1, field_2)
      @operator = operator
      @field_1 = field_1
      @field_2 = field_2
    end

    # @return [Symbol] :self or :dual
    def kind
      if @field_1 == @field_2
        :self
      else
        :dual
      end
    end

    # @return [Symbol] name of the merged field (for :dual) types
    def name
      merged_field.name
    end

    # @return [Linkage::Field] result of Field#merge between the two fields
    def merged_field
      @merged_field ||= @field_1.merge(@field_2)
    end

    # Apply changes to a dataset based on the expectation, such as
    # calling {Dataset#add_order} and {Dataset#add_select} with the
    # appropriate arguments
    def apply_to(dataset)
      as = name != @field_1.name ? name : nil
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

  class MustExpectation < Expectation
  end

  Expectation::TYPES = { :must => MustExpectation }
end
