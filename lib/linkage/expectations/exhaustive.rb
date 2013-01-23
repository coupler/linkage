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
        if @kind.nil?
          if @comparator.lhs_args.length != @comparator.rhs_args.length
            @kind = :cross
          else
            @kind = :self
            @comparator.lhs_args.each_with_index do |lhs_arg, index|
              rhs_arg = @comparator.rhs_args[index]
              if !lhs_arg.objects_equal?(rhs_arg)
                @kind = :cross
                break
              end
            end
          end

          # Check for dual-linkage.
          if @kind == :cross
            # Assume that all lhs arguments have the same dataset, as well
            # as all the rhs arguments. Only check the first argument of each
            # side.
            lhs_arg = @comparator.lhs_args[0]
            rhs_arg = @comparator.rhs_args[0]
            if !lhs_arg.datasets_equal?(rhs_arg)
              @kind = :dual
            end
          end
        end
        @kind
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
