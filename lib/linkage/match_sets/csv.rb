require 'csv'

module Linkage
  module MatchSets
    class CSV < MatchSet
      def initialize(filename)
        @filename = filename
      end

      def open_for_writing
        return if @mode == :write
        @csv = ::CSV.open(@filename, 'wb')
        @csv << %w{id_1 id_2 score}
        @mode = :write
      end

      def add_match(id_1, id_2, score)
        raise "not in write mode" if @mode != :write
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
