require 'csv'

module Linkage
  module ResultSets
    class CSV < ResultSet
      def initialize(filename)
        @filename = filename
      end

      def open_for_reading
        raise "already open for writing, try closing first" if @mode == :write
        return if @mode == :read
        @csv = ::CSV.open(@filename, 'rb', :headers => true)
        @mode = :read
      end

      def open_for_writing
        raise "already open for reading, try closing first" if @mode == :read
        return if @mode == :write
        @csv = ::CSV.open(@filename, 'wb')
        @csv << %w{comparator id_1 id_2 score}
        @mode = :write
      end

      def add_score(comparator_index, id_1, id_2, score)
        raise "not in write mode" if @mode != :write
        @csv << [comparator_index, id_1, id_2, score]
      end

      def each_pair
        open_for_reading

        pairs = {}
        @csv.each do |row|
          pair = [row['id_1'], row['id_2']]
          scores = pairs[pair] || []
          scores.push([row['comparator'].to_i, row['score'].to_i])
          pairs[pair] = scores
        end
        pairs.each_pair do |pair, scores|
          yield pair[0], pair[1], scores
        end

        close
      end

      def close
        @mode = nil
        @csv.close if @csv
      end
    end

    ResultSet.register('csv', CSV)
  end
end
