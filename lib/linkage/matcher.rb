module Linkage
  class Matcher
    include Observable

    def initialize(result_set)
      @result_set = result_set
    end

    def mean(threshold)
      @result_set.each_pair do |id_1, id_2, scores|
        mean = scores.inject(:+) / scores.length.to_f
        if mean >= threshold
          changed
          notify_observers(id_1, id_2, mean)
        end
      end
    end
  end
end
