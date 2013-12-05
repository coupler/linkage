module Linkage
  module Comparators
    class Compare < Comparator
      VALID_OPERATIONS = [
        :not_equal, :greater_than, :greater_than_or_equal_to,
        :less_than_or_equal_to, :less_than
      ]

      def initialize(set_1, set_2, operation)
        if set_1.length != set_2.length
          raise "sets must be of equal length"
        end

        # Check value data types
        set_1.each_with_index do |value_1, index|
          value_2 = set_2[index]
          if value_1.ruby_type != value_2.ruby_type
            raise "values at index #{index} had different types"
          end
        end

        # Check compare operator
        if !VALID_OPERATIONS.include?(operation)
          raise "operation is not valid"
        end

        @set_1 = set_1
        @set_2 = set_2
        @operation = operation
      end

      def score(record_1, record_2)
        name_1 = @set_1[0].name
        name_2 = @set_2[0].name

        result =
          case @operation
          when :not_equal
            record_1[name_1] != record_2[name_2]
          when :greater_than
            record_1[name_1] > record_2[name_2]
          when :greater_than_or_equal_to
            record_1[name_1] >= record_2[name_2]
          when :less_than_or_equal_to
            record_1[name_1] <= record_2[name_2]
          when :less_than
            record_1[name_1] < record_2[name_2]
          end

        result ? 1 : 0
      end
    end

    Comparator.register('compare', Compare)
  end
end
