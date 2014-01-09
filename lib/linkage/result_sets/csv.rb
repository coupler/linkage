require 'csv'

module Linkage
  module ResultSets
    class CSV < ResultSet
      def initialize(filename)
        @csv = ::CSV.open(filename, 'wb')
        @csv << %w{comparator id_1 id_2 score}
      end

      def add_score(comparator, record_1, record_2, score)
        index = comparators.index(comparator)
        @csv << [index + 1, record_1[primary_key_1], record_2[primary_key_2], score]
      end

      def close
        @csv.close
      end
    end

    ResultSet.register('csv', CSV)
  end
end
