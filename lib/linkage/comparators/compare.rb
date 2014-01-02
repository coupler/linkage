module Linkage
  module Comparators
    class Compare < Comparator
      VALID_OPERATIONS = [
        :not_equal, :greater_than, :greater_than_or_equal_to,
        :less_than_or_equal_to, :less_than, :equal_to
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
        @type = operation == :equal_to ? :advanced : :simple

        @set_1 = set_1
        @set_2 = set_2
        @operation = operation
      end

      def score(record_1, record_2)
        # TODO: multiple field matches?
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

      def score_datasets(dataset_1, dataset_2)
        # FIXME: nil value equality

        _score_datasets(dataset_1, dataset_2)
      end

      def score_dataset(dataset)
        # FIXME: nil value equality

        name = @set_1.collect(&:name)
        if @set_2.collect(&:name) != name
          return _score_datasets(dataset, dataset)
        end

        enum = dataset.order(*name).to_enum
        begin
          record = enum.next
        rescue StopIteration
          return
        end
        group = [record]
        last_value = record.values_at(*name)
        loop do
          begin
            record = enum.next
          rescue StopIteration
            break
          end
          value = record.values_at(*name)
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
        name_1 = @set_1.collect(&:name)
        name_2 = @set_2.collect(&:name)
        enum_1 = dataset_1.order(*name_1).to_enum
        enum_2 = dataset_2.order(*name_2).to_enum

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
          value_1 = record_1.values_at(*name_1)
          value_2 = record_2.values_at(*name_2)
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
                  value_1 = record_1.values_at(*name_1)
                  result = last_value == value_1
                when :right
                  record_2 = enum_2.next
                  value_2 = record_2.values_at(*name_2)
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
            notify_observers(record_1, record_2, 1)
          end
        end
      end

      def score_group(group)
        (group.length - 1).times do |i|
          ((i+1)...group.length).each do |j|
            changed
            notify_observers(group[i], group[j], 1)
          end
        end
      end
    end

    Comparator.register('compare', Compare)
  end
end
