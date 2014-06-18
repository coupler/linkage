module Linkage
  # {Matcher} is responsible for combining scores from a {ScoreSet} and deciding
  # which pairs of records match. There are two parameters you can use to
  # determine how {Matcher} does this: `algorithm` and `threshold`.
  #
  # There are currently two algorithm options: `:mean` and `:sum`. The mean
  # algorithm will create a mean score for each pair of records. The sum
  # algorithm will create a total score for each pair of records.
  #
  # The `threshold` parameter determines what is considered a match. If the
  # result score for a pair of records (depending on the algorithm used) is
  # greater than or equal to the threshold, then the pair is considered to be a
  # match.
  #
  # Whenever {Matcher} finds a match, it uses the observer pattern to notify
  # other objects that a match has been found. Usually the only observer is a
  # {MatchSet}, which is responsible for actually saving match information.
  class Matcher
    include Observable

    attr_reader :comparators, :score_set, :algorithm, :threshold

    # @param comparators [Array<Comparator>]
    # @param score_set [ScoreSet]
    # @param algorithm [Symbol] `:mean` or `:sum`
    # @param threshold [Numeric]
    def initialize(comparators, score_set, algorithm, threshold)
      @comparators = comparators
      @score_set = score_set
      @algorithm = algorithm
      @threshold = threshold
    end

    # Find matches.
    def run
      send(@algorithm)
    end

    # Combine scores for each pair of records via mean, then compare the
    # combined score to the threshold. Notify observers if there's a match.
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

    # Combine scores for each pair of records via sum, then compare the
    # combined score to the threshold. Notify observers if there's a match.
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
