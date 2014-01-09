module Linkage
  class ResultSet
    # Register a result set.
    #
    # @param [Class] klass
    def self.register(name, klass)
      methods = klass.instance_methods(false)
      if !methods.include?(:add_score)
        raise ArgumentError, "class must define #add_score"
      end

      @result_sets ||= {}
      @result_sets[name] = klass
    end

    def self.[](name)
      @result_sets ? @result_sets[name] : nil
    end

    attr_accessor :primary_key_1, :primary_key_2

    # @abstract
    def add_score(comparator, record_1, record_2, value)
      raise NotImplementedError
    end

    def comparators
      @comparators ||= []
    end

    def add_comparator(comparator)
      comparators << comparator
    end

    def close
    end
  end
end

require 'linkage/result_sets/csv'
