require 'csv'

module Linkage
  module MatchSets
    class CSV < MatchSet
      def initialize(options = {})
        @filename = options[:filename] || "matches.csv"
        if options[:dir]
          dir = File.expand_path(options[:dir])
          FileUtils.mkdir_p(dir)
          @filename = File.join(dir, @filename)
        end
        @overwrite = options[:overwrite]
      end

      def open_for_writing
        return if @mode == :write

        if !@overwrite && File.exist?(@filename)
          raise ExistsError, "#{@filename} exists and not in overwrite mode"
        end

        @csv = ::CSV.open(@filename, 'wb')
        @csv << %w{id_1 id_2 score}
        @mode = :write
      end

      def add_match(id_1, id_2, score)
        raise "not in write mode" if @mode != :write
        if score.equal?(1.0) || score.equal?(0.0)
          score = score.floor
        end
        @csv << [id_1, id_2, score]
      end

      def close
        @mode = nil
        @csv.close if @csv
      end
    end

    MatchSet.register('csv', CSV)
  end
end
