module Linkage
  # @abstract Abstract class to represent record comparators.
  class Comparator
    include Observable

    # Register a new comparator.
    #
    # @param [Class] klass Comparator subclass
    def self.register(name, klass)
      methods = klass.instance_methods(false)
      if !methods.include?(:score) && (!methods.include?(:score_datasets) || !methods.include?(:score_dataset))
        raise ArgumentError, "class must define either #score or both #score_datasets and #score_dataset methods"
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

    def type
      @type || :simple
    end

    # @abstract Override this to return the score of the linkage strength of
    #   two records.
    # @return [Numeric]
    def score(record_1, record_2)
      raise NotImplementedError
    end
  end
end

path = File.expand_path(File.join(File.dirname(__FILE__), "comparators"))
require File.join(path, "compare")
require File.join(path, "within")
require File.join(path, "strcompare")
