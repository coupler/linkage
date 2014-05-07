module Linkage
  # A {MatchSet} is responsible for keeping track of matches. After the scoring
  # process, a {Matcher} uses scores from a {ScoreSet} to calculate which record
  # pairs match. Those pairs are then recorded by a {MatchRecorder} to a
  # {MatchSet}.
  #
  # {MatchSet} is the superclass of implementations for different formats.
  # Currently there are two formats for storing matches:
  #
  # * CSV ({MatchSets::CSV})
  # * Database ({MatchSets::Database})
  #
  # See the documentation for match set you're interested in for more
  # information.
  #
  # If you want to implement a custom {MatchSet}, create a class that inherits
  # {MatchSet} and defines at least {#add_match}. You can then register that
  # class via {.register}.
  #
  # @abstract
  class MatchSet
    class << self
      # Register a new match set. Subclasses must define at least {#add_match},
      # otherwise an `ArgumentError` will be raised.
      #
      # @param [String] name Match set name used in {.klass_for}
      # @param [Class] klass MatchSet subclass
      def register(name, klass)
        methods = klass.instance_methods(false)
        unless methods.include?(:add_match)
          raise ArgumentError, "class must define #add_match"
        end

        @match_sets ||= {}
        @match_sets[name] = klass
      end

      # Return a registered MatchSet subclass or `nil` if it doesn't exist.
      #
      # @param [String] name of registered match set
      # @return [Class, nil]
      def klass_for(name)
        @match_sets ? @match_sets[name] : nil
      end
      alias :[] :klass_for
    end

    # This is called by {MatchRecorder#start}, before any matches are added via
    # {#add_match}. Subclasses can redefine this to perform any setup needed for
    # saving matches.
    def open_for_writing
    end

    # Add a match to the MatchSet. Subclasses must redefine this.
    #
    # @param id_1 [Object] record id from first dataset
    # @param id_2 [Object] record id from second dataset
    # @param value [Fixnum, Float] match value
    # @abstract
    def add_match(id_1, id_2, score)
      raise NotImplementedError
    end

    # This is called by {MatchRecorder#stop}, after all matches have been added.
    # Subclasses can redefine this to perform any teardown needed.
    def close
    end
  end
end

require 'linkage/match_sets/csv'
require 'linkage/match_sets/database'
