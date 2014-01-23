module Linkage
  class Recorder
    def initialize(result_set, primary_keys)
      @result_set = result_set
      @primary_keys = primary_keys
      @comparators = []
    end

    def listen_to(comparator)
      comparator.add_observer(self)
      @comparators << comparator
    end

    def update(comparator, record_1, record_2, score)
      index = @comparators.index(comparator)
      primary_key_1 = record_1[@primary_keys[0]]
      primary_key_2 = record_2[@primary_keys[1]]
      @result_set.add_score(index + 1, primary_key_1, primary_key_2, score)
    end

    def stop_listening
      @comparators.each do |comparator|
        comparator.delete_observer(self)
      end
      @comparators.clear
    end
  end
end
