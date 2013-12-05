module Linkage
  # @abstract Abstract class to represent record comparators.
  class Comparator
    # Register a new comparator.
    #
    # @param [Class] klass Comparator subclass
    def self.register(klass)
      name = nil
      begin
        name = klass.comparator_name
      rescue NotImplementedError
        raise ArgumentError, "comparator_name class method must be defined"
      end

      if !klass.instance_methods(false).include?(:score)
        raise ArgumentError, "class must define the score method"
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
  end
end

path = File.expand_path(File.join(File.dirname(__FILE__), "comparators"))
require File.join(path, "compare")
require File.join(path, "within")
require File.join(path, "strcompare")
