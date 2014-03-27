require 'csv'

module Linkage
  module MatchSets
    class CSV < MatchSet
      include Helpers::CSV

      DEFAULT_OPTIONS = {
        :filename => 'matches.csv'
      }

      def initialize(options = {})
        @options = DEFAULT_OPTIONS.merge(options.reject { |k, v| v.nil? })
      end

      def open_for_writing
        return if @mode == :write

        @csv = open_csv_for_writing(@options)
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
