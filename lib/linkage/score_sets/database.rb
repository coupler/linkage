module Linkage
  module ScoreSets
    class Database < ScoreSet
      def initialize(database, options = {})
        @database = database
        @table_name = options[:table_name] || :scores
        @overwrite = options[:overwrite]
      end

      def open_for_reading
        raise "already open for writing, try closing first" if @mode == :write
        return if @mode == :read

        if !@database.table_exists?(@table_name)
          raise MissingError, "#{@table_name} table does not exist"
        end

        @dataset = @database[@table_name]
        @mode = :read
      end

      def open_for_writing
        raise "already open for reading, try closing first" if @mode == :read
        return if @mode == :write

        if @overwrite
          @database.drop_table?(@table_name)
        elsif @database.table_exists?(@table_name)
          raise ExistsError, "#{@table_name} table exists and not in overwrite mode"
        end

        @database.create_table(@table_name) do
          Integer :comparator_id
          String :id_1
          String :id_2
          Float :score
        end
        @dataset = @database[@table_name]
        @mode = :write
      end

      def add_score(comparator_id, id_1, id_2, score)
        raise "not in write mode" if @mode != :write

        @dataset.insert({
          :comparator_id => comparator_id,
          :id_1 => id_1,
          :id_2 => id_2,
          :score => score
        })
      end

      def each_pair
        open_for_reading

        current_pair = nil
        @dataset.order(:id_1, :id_2, :comparator_id).each do |row|
          if current_pair.nil? || current_pair[0] != row[:id_1] || current_pair[1] != row[:id_2]
            yield(*current_pair) unless current_pair.nil?
            current_pair = [row[:id_1], row[:id_2], []]
          end
          scores = current_pair[2]

          comparator_id = row[:comparator_id] - 1
          scores[comparator_id] = row[:score]
        end
        yield(*current_pair) unless current_pair.nil?

        close
      end

      def close
        @mode = nil
      end
    end

    ScoreSet.register('database', Database)
  end
end
