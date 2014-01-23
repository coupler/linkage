module Linkage
  class MatchSet
    # Register a match set.
    #
    # @param [Class] klass
    def self.register(name, klass)
      methods = klass.instance_methods(false)
      unless methods.include?(:add_match)
        raise ArgumentError, "class must define #add_match"
      end

      @match_sets ||= {}
      @match_sets[name] = klass
    end

    def self.[](name)
      @match_sets ? @match_sets[name] : nil
    end

    def open_for_writing
    end

    # @abstract
    def add_match(id_1, id_2, score)
      raise NotImplementedError
    end

    def close
    end
  end
end

require 'linkage/match_sets/csv'
