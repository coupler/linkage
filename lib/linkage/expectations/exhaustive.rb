module Linkage
  module Expectations
    class Exhaustive < Expectation
      attr_reader :comparator, :threshold, :mode

      def initialize(comparator, threshold, mode)
        @comparator = comparator
        @threshold = threshold
        @mode = mode
      end

      def kind
        :exhaustive
      end
    end
  end
end
