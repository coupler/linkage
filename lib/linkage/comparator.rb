module Linkage
  # @abstract Abstract class to represent record comparators.
  class Comparator
    include Observable

    # Register a new comparator.
    #
    # @param [Class] klass Comparator subclass
    def self.register(name, klass)
      methods = klass.instance_methods(false)
      if !methods.include?(:score) && !methods.include?(:score_datasets)
        raise ArgumentError, "class must define either #score or #score_datasets"
      end

      @comparators ||= {}
      @comparators[name] = klass
    end

    def self.[](name)
      @comparators ? @comparators[name] : nil
    end

    # @abstract Override this to return the name of the comparator.
    # @return [String]
    def self.comparator_name
      raise NotImplementedError
    end

    # @abstract Override this to return the score of the linkage strength of
    #   two records.
    # @return [Numeric]
    def score(record_1, record_2)
      raise NotImplementedError
    end

    # Default algorithm for scoring datasets. Calls the score method for each
    # pair of records.
    def score_datasets(dataset_1, dataset_2 = nil)
      if dataset_2
        dataset_1.each do |record_1|
          dataset_2.each do |record_2|
            score_and_notify(record_1, record_2)
          end
        end
      else
        # very naive implementation
        records = dataset_1.all
        0.upto(records.length - 2) do |i|
          record_1 = records[i]
          (i + 1).upto(records.length - 1) do |j|
            record_2 = records[j]
            score_and_notify(record_1, record_2)
          end
        end
      end
    end

    protected

    def score_and_notify(record_1, record_2)
      value = score(record_1, record_2)
      changed
      notify_observers(record_1, record_2, value)
    end
  end
end

path = File.expand_path(File.join(File.dirname(__FILE__), "comparators"))
require File.join(path, "compare")
require File.join(path, "within")
require File.join(path, "strcompare")
