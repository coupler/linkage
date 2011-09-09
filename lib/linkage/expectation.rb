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

    # @return [Symbol] :join or :filter
    def kind
      if @field_1.dataset != @field_2.dataset
        :join
      end
    end
  end

  class MustExpectation < Expectation
  end

  TYPES = {
    :must => MustExpectation
  }
end
