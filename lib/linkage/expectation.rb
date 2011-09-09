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
  end

  class MustExpectation < Expectation
  end

  TYPES = {
    :must => MustExpectation
  }
end
