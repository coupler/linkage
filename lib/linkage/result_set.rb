module Linkage
  # A {ResultSet} contains a {ScoreSet} and a {MatchSet}. To understand the
  # purpose of a {ResultSet}, it helps to understand the recording process
  # first.
  #
  # During a record linkage, one or more {Comparator}s generate scores. Each
  # score is recorded by a {ScoreRecorder}, which uses a {ScoreSet} to actually
  # save the score. After the scoring is complete, a {Matcher} combines the
  # scores to create matches. Each match is recorded by a {MatchRecorder}, which
  # uses a {MatchSet} to actually save the score.
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

require 'linkage/result_sets/csv'
require 'linkage/result_sets/database'
