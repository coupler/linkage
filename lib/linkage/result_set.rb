module Linkage
  class ResultSet
    # Register a result set.
    #
    # @param [Class] klass
    def self.register(name, klass)
      methods = klass.instance_methods(false)
      missing = []
      unless methods.include?(:score_set)
        missing.push("#score_set")
      end
      unless methods.include?(:match_set)
        missing.push("#match_set")
      end
      unless missing.empty?
        raise ArgumentError, "class must define #{missing.join(" and ")}"
      end

      @result_set ||= {}
      @result_set[name] = klass
    end

    def self.[](name)
      @result_set ? @result_set[name] : nil
    end

    # @abstract
    def score_set
      raise NotImplementedError
    end

    # @abstract
    def match_set
      raise NotImplementedError
    end
  end
end
