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

    # @abstract
    def add_score(comparator_index, id_1, id_2, value)
      raise NotImplementedError
    end

    def close
    end
  end
end

require 'linkage/result_sets/csv'
