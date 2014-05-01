module Linkage
  class Matcher
    include Observable

    attr_reader :comparators, :score_set, :algorithm, :threshold

    def initialize(comparators, score_set, algorithm, threshold)
      @comparators = comparators
      @score_set = score_set
      @algorithm = algorithm
      @threshold = threshold
    end

    def run
      send(@algorithm)
    end

    def mean
      w = @comparators.collect { |comparator| comparator.weight || 1 }
      @score_set.open_for_reading
      @score_set.each_pair do |id_1, id_2, scores|
        sum = 0
        scores.each do |key, value|
          sum += value * w[key-1]
        end
        mean = sum / @comparators.length.to_f
        if mean >= @threshold
          changed
          notify_observers(id_1, id_2, mean)
        end
      end
      @score_set.close
    end

    def sum
      w = @comparators.collect { |comparator| comparator.weight || 1 }
      @score_set.open_for_reading
      @score_set.each_pair do |id_1, id_2, scores|
        sum = 0
        scores.each do |key, value|
          sum += value * w[key-1]
        end
        if sum >= @threshold
          changed
          notify_observers(id_1, id_2, sum)
        end
      end
      @score_set.close
    end
  end
end
