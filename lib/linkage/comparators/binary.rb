module Linkage
  module Comparators
    # @abstract Convenient abstract class for comparators that only return
    #   true/false values (0 or 1).
    class Binary < Comparator
      @@score_range = 0..1
      def self.score_range
        @@score_range
      end
    end
  end
end
