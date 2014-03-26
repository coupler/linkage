require 'csv'

module Linkage
  module ScoreSets
    class CSV < ScoreSet
      def initialize(options = {})
        @filename = options[:filename] || "scores.csv"
        if options[:dir]
          dir = File.expand_path(options[:dir])
          FileUtils.mkdir_p(dir)
          @filename = File.join(dir, @filename)
        end
        @overwrite = options[:overwrite]
      end

      def open_for_reading
        raise "already open for writing, try closing first" if @mode == :write
        return if @mode == :read

        if !File.exist?(@filename)
          raise MissingError, "#{@filename} does not exist"
        end
        @csv = ::CSV.open(@filename, 'rb', :headers => true)
        @mode = :read
      end

      def open_for_writing
        raise "already open for reading, try closing first" if @mode == :read
        return if @mode == :write

        if !@overwrite && File.exist?(@filename)
          raise ExistsError, "#{@filename} exists and not in overwrite mode"
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
        raise "not in read mode" if @mode != :read

        pairs = Hash.new { |h, k| h[k] = {} }
        @csv.each do |row|
          key = [row['id_1'], row['id_2']]
          score = row['score']
          pairs[key][row['comparator_id'].to_i] = score.to_f
        end
        pairs.each_pair do |pair, scores|
          yield pair[0], pair[1], scores
        end
      end

      def close
        @mode = nil
        @csv.close if @csv
      end
    end

    ScoreSet.register('csv', CSV)
  end
end
