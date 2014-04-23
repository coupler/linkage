module Linkage
  # A {ResultSet} contains a {ScoreSet} and a {MatchSet}. To understand the
  # purpose of a {ResultSet}, it helps to understand the recording process
  # first.
  #
  # During a record linkage, one or more {Comparator}s generate scores. Each
  # score is recorded by a {ScoreRecorder}, which uses a {ScoreSet} to actually
  # save the score. After the scoring is complete, a {Matcher} combines the
  # scores to create matches. Each match is recorded by a {MatchRecorder}, which
  # uses a {MatchSet} to actually save the match information.
  #
  # So to save scores and matches, we need both a {ScoreSet} and a {MatchSet}.
  # To make this easier, a {ResultSet} configures both.
  #
  # {ResultSet} is the superclass of implementations for different formats.
  # Currently there are two formats for storing scores and matches:
  #
  # * CSV ({ResultSets::CSV})
  # * Database ({ResultSets::Database})
  #
  # See the documentation for result set you're interested in for more
  # information.
  #
  # If you want to implement a custom {ResultSet}, create a class that inherits
  # {ResultSet} and defines both {#score_set} that returns a {ScoreSet} and
  # {#match_set} that returns a {MatchSet}. You can then register that class via
  # {.register}.
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
