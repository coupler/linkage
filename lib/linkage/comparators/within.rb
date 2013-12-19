module Linkage
  module Comparators
    class Within < Comparator
      def initialize(field_1, field_2, value)
        if field_1.ruby_type != field_2.ruby_type
          raise "fields must have the same type"
        end

        @name_1 = field_1.name
        @name_2 = field_2.name
        @value = value
      end

      def score(record_1, record_2)
        (record_1[@name_1] - record_2[@name_2]).abs <= @value ? 1 : 0
      end
    end

    Comparator.register('within', Within)
  end
end
