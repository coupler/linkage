require 'csv'

module Linkage
  module ResultSets
    class CSV < ResultSet
      def initialize(filename)
        @csv = ::CSV.open(filename, 'wb')
        @csv << %w{comparator id_1 id_2 score}
      end

      def add_score(comparator_index, id_1, id_2, score)
        @csv << [comparator_index, id_1, id_2, score]
      end

      def close
        @csv.close
      end
    end

    ResultSet.register('csv', CSV)
  end
end
