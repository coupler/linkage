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

      def apply_to(dataset, side)
        exprs =
          case side
          when :lhs
            comparator.lhs_args.collect(&:to_expr)
          when :rhs
            comparator.rhs_args.collect(&:to_expr)
          end
        dataset.select_more(*exprs)
      end
    end
  end
end
