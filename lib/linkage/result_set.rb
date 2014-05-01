module Linkage
  # A {ResultSet} is a convenience class for wrapping a {ScoreSet} and a
  # {MatchSet}. Most of the time, you'll want to use the same storage format for
  # both scores and matches. {ResultSet} provides a way to group both sets
  # together.
  #
  # The default implementation of {ResultSet} merely returns whatever {ScoreSet}
  # and {MatchSet} you pass to it during creation (see {#initialize}). However,
  # {ResultSet} can be subclassed to provide easy initialization of sets of the
  # same format. Currently there are two subclasses:
  #
  # * CSV ({ResultSets::CSV})
  # * Database ({ResultSets::Database})
  #
  # If you want to implement a custom {ResultSet}, create a class that inherits
  # {ResultSet} and defines both {#score_set} and {#match_set} to return a
  # {ScoreSet} and {MatchSet} respectively. You can then register that class via
  # {.register} to make it easier to use.
  class ResultSet
    class << self
      # Register a new result set. Subclasses must define {#score_set} and
      # {#match_set}.  Otherwise, an `ArgumentError` will be raised when you try
      # to call {.register}.
      #
      # @param [String] name Result set name used in {.klass_for}
      # @param [Class] klass ResultSet subclass
      def register(name, klass)
        methods = klass.instance_methods
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

      # Return a registered ResultSet subclass or `nil` if it doesn't exist.
      #
      # @param [String] name of registered result set
      # @return [Class, nil]
      def klass_for(name)
        @result_set ? @result_set[name] : nil
      end
      alias :[] :klass_for
    end

    # @param [ScoreSet] score_set
    # @param [MatchSet] match_set
    def initialize(score_set, match_set)
      @score_set = score_set
      @match_set = match_set
    end

    # Returns a {ScoreSet}.
    #
    # @return [ScoreSet]
    def score_set
      @score_set
    end

    # Returns a {MatchSet}.
    #
    # @return [MatchSet]
    def match_set
      @match_set
    end
  end
end

require 'linkage/result_sets/csv'
require 'linkage/result_sets/database'
