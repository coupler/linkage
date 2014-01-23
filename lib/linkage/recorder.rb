module Linkage
  class Recorder
    def initialize(comparators, score_set, primary_keys)
      @comparators = comparators
      @score_set = score_set
      @primary_keys = primary_keys
    end

    def start
      @comparators.each do |comparator|
        comparator.add_observer(self)
      end
      @score_set.open_for_writing
    end

    def update(comparator, record_1, record_2, score)
      index = @comparators.index(comparator)
      primary_key_1 = record_1[@primary_keys[0]]
      primary_key_2 = record_2[@primary_keys[1]]
      @score_set.add_score(index + 1, primary_key_1, primary_key_2, score)
    end

    def stop
      @score_set.close
      @comparators.each do |comparator|
        comparator.delete_observer(self)
      end
    end
  end
end
