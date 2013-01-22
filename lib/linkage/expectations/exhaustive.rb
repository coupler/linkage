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
            comparator.lhs_args.collect { |arg| arg.to_expr.as(arg.name) }
          when :rhs
            comparator.rhs_args.collect { |arg| arg.to_expr.as(arg.name) }
          end
        dataset.select_more(*exprs)
      end

      def satisfied?(score)
        case mode
        when :equal
          score == threshold
        when :min
          score >= threshold
        end
      end
    end
  end
end
