module Linkage
  module Comparators
    # Compare is the most basic comparator in Linkage, conceptually. It scores
    # two records based on whether or not field values satisfy the specified
    # operator. Score is either 0 or 1.
    #
    # To use Compare, you must specify two sets of fields to use in the
    # comparison, along with an operator. Valid operators are:
    #
    # * `:equal`
    # * `:not_equal`
    # * `:greater_than`
    # * `:greater_than_or_equal`
    # * `:less_than`
    # * `:less_than_or_equal`
    #
    # Sets of fields must be of equal length. If you specify more than one
    # field, each field will be compared to its counterpart in the other set.
    # All of the field values must meet the conditions in order for the score to
    # be 1. Otherwise, the score is 0.
    #
    # Consider the following example, using a {Configuration} as part of
    # {Dataset#link_with}:
    #
    # ```ruby
    # config.compare([:foo, :bar], [:baz, :qux], :equal)
    # ```
    #
    # For each record, the values of `foo` and `baz` are compared, and the
    # values of `bar` and `qux` are compared. If both of these two comparisons
    # are `true`, then the score of 1 is given. If `foo` and `baz` are equal but
    # `bar` and `qux` are not equal, or if both comparisons are false, then a
    # score of 0 is given.
    #
    # Algorithms
    # ----------
    #
    # The way records are chosen for comparison depends on which operator you
    # use. The `:equal` operator is treated differently than the other
    # operators. When using operators other than `:equal`, each record is
    # compared to every other record (and {#type} returns `:simple`). When using
    # `:equal`, {#type} is `:advanced` and a different algorithm is used.
    #
    # "Equal" mode uses an algorithm similar to the sorted neighborhood method.
    # Values are sorted (via database query) and then compared. This way, only
    # adjacent records are compared. Using the transitive property of equality,
    # records are grouped together. All pairs of records in the group are scored
    # as 1. Scores of 0 are not given at all (absence of score means 0).
    class Compare < Comparator
      VALID_OPERATIONS = [
        :not_equal, :greater_than, :greater_than_or_equal,
        :less_than_or_equal, :less_than, :equal
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
        @type = operation == :equal ? :advanced : :simple
        @names_1 = set_1.collect(&:name)
        @names_2 = set_2.collect(&:name)
        @operation = operation
      end

      def score(record_1, record_2)
        values_1 = record_1.values_at(*@names_1)
        values_2 = record_2.values_at(*@names_2)
        result =
          case @operation
          when :not_equal
            values_1.each_with_index.all? do |value_1, i|
              value_1 != values_2[i]
            end
          when :greater_than
            values_1.each_with_index.all? do |value_1, i|
              value_1 > values_2[i]
            end
          when :greater_than_or_equal
            values_1.each_with_index.all? do |value_1, i|
              value_1 >= values_2[i]
            end
          when :less_than_or_equal
            values_1.each_with_index.all? do |value_1, i|
              value_1 <= values_2[i]
            end
          when :less_than
            values_1.each_with_index.all? do |value_1, i|
              value_1 < values_2[i]
            end
          end

        result ? 1 : 0
      end

      def score_datasets(dataset_1, dataset_2)
        # FIXME: nil value equality

        _score_datasets(dataset_1, dataset_2)
      end

      def score_dataset(dataset)
        # FIXME: nil value equality

        if @names_1 != @names_2
          return _score_datasets(dataset, dataset)
        end

        enum = dataset.order(*@names_1).to_enum
        begin
          record = enum.next
        rescue StopIteration
          return
        end
        group = [record]
        last_value = record.values_at(*@names_1)
        loop do
          begin
            record = enum.next
          rescue StopIteration
            break
          end
          value = record.values_at(*@names_1)
          if value == last_value
            group << record
          else
            score_group(group)
            group.clear
            group << record
            last_value = value
          end
        end
        score_group(group)
      end

      private

      def _score_datasets(dataset_1, dataset_2)
        enum_1 = dataset_1.order(*@names_1).to_enum
        enum_2 = dataset_2.order(*@names_2).to_enum

        begin
          record_1 = enum_1.next
          record_2 = enum_2.next
        rescue StopIteration
          # no pairs to score
          return
        end
        group_1 = []
        group_2 = []
        loop do
          value_1 = record_1.values_at(*@names_1)
          value_2 = record_2.values_at(*@names_2)
          result = value_1 <=> value_2
          if result == 0
            last_value = value_1
            group_1 << record_1
            group_2 << record_2

            state = :right
            loop do
              begin
                case state
                when :left
                  record_1 = enum_1.next
                  value_1 = record_1.values_at(*@names_1)
                  result = last_value == value_1
                when :right
                  record_2 = enum_2.next
                  value_2 = record_2.values_at(*@names_2)
                  result = last_value == value_2
                end
              rescue StopIteration
                result = false
                case state
                when :left
                  record_1 = :eof
                when :right
                  record_2 = :eof
                end
              end

              if result
                case state
                when :left
                  group_1 << record_1
                when :right
                  group_2 << record_2
                end
              else
                case state
                when :left
                  # done with this group
                  score_groups(group_1, group_2)
                  group_1.clear
                  group_2.clear
                  break
                when :right
                  state = :left
                end
              end
            end
            if record_1 == :eof || record_2 == :eof
              break
            end
          else
            begin
              if result < 0
                record_1 = enum_1.next
              else
                record_2 = enum_2.next
              end
            rescue StopIteration
              break
            end
          end
        end
      end

      def score_groups(group_1, group_2)
        group_1.each do |record_1|
          group_2.each do |record_2|
            changed
            notify_observers(self, record_1, record_2, 1)
          end
        end
      end

      def score_group(group)
        (group.length - 1).times do |i|
          ((i+1)...group.length).each do |j|
            changed
            notify_observers(self, group[i], group[j], 1)
          end
        end
      end
    end

    Comparator.register('compare', Compare)
  end
end
