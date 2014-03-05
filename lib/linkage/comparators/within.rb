module Linkage
  module Comparators
    # Within is a integer comparator. It checks if two values are within a
    # specified range. Score is either 0 to 1.
    #
    # To use Within, you must specify one field for each record to use in
    # the comparison, along with a range value.
    #
    # Consider the following example, using a {Configuration} as part of
    # {Dataset#link_with}:
    #
    # ```ruby
    # config.within(:foo, :bar, 5)
    # ```
    #
    # For each pair of records, if value of `foo` is within 5 (inclusive) of
    # the value of `bar`, the score is 1. Otherwise, the score is 0.
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
