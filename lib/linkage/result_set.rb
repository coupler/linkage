module Linkage
  class ResultSet
    # Register a result set.
    #
    # @param [Class] klass
    def self.register(name, klass)
      methods = klass.instance_methods(false)
      missing = []
      unless methods.include?(:add_score)
        missing.push("#add_score")
      end
      unless methods.include?(:each_pair)
        missing.push("#each_pair")
      end
      unless missing.empty?
        raise ArgumentError, "class must define #{missing.join(" and ")}"
      end

      @result_sets ||= {}
      @result_sets[name] = klass
    end

    def self.[](name)
      @result_sets ? @result_sets[name] : nil
    end

    def open_for_reading
    end

    def open_for_writing
    end

    # @abstract
    def add_score(comparator_index, id_1, id_2, value)
      raise NotImplementedError
    end

    # @abstract
    def each_pair(&block)
      raise NotImplementedError
    end

    def close
    end
  end
end

require 'linkage/result_sets/csv'
