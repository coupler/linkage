module Linkage
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
end
