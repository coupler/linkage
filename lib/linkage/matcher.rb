module Linkage
  class Matcher
    include Observable

    attr_reader :score_set, :algorithm, :threshold

    def initialize(score_set, algorithm, threshold)
      @score_set = score_set
      @algorithm = algorithm
      @threshold = threshold
    end

    def run
      send(@algorithm)
    end

    private

    def mean
      @score_set.each_pair do |id_1, id_2, scores|
        mean = scores.inject(:+) / scores.length.to_f
        if mean >= @threshold
          changed
          notify_observers(id_1, id_2, mean)
        end
      end
    end
  end
end
