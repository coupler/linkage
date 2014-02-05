require 'csv'

module Linkage
  module ScoreSets
    class CSV < ScoreSet
      def initialize(filename, options = {})
        @filename = filename
        @overwrite = options[:overwrite]
      end

      def open_for_reading
        raise "already open for writing, try closing first" if @mode == :write
        return if @mode == :read

        if !File.exist?(@filename)
          raise FileMissingError, "#{@filename} does not exist"
        end
        @csv = ::CSV.open(@filename, 'rb', :headers => true)
        @mode = :read
      end

      def open_for_writing
        raise "already open for reading, try closing first" if @mode == :read
        return if @mode == :write

        if !@overwrite && File.exist?(@filename)
          raise FileExistsError, "#{@filename} exists and not in overwrite mode"
        end

        @csv = ::CSV.open(@filename, 'wb')
        @csv << %w{comparator_id id_1 id_2 score}
        @mode = :write
      end

      def add_score(comparator_id, id_1, id_2, score)
        raise "not in write mode" if @mode != :write
        @csv << [comparator_id, id_1, id_2, score]
      end

      def each_pair
        open_for_reading

        pairs = {}
        @csv.each do |row|
          pair = [row['id_1'], row['id_2']]
          scores = pairs[pair] || []

          comparator_id = row['comparator_id'].to_i - 1
          scores[comparator_id] = row['score'].to_f
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

    ScoreSet.register('csv', CSV)
  end
end
