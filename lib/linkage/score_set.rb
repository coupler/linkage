module Linkage
  # A {ScoreSet} is responsible for keeping track of scores. During the record
  # linkage process, one or more {Comparator}s generate scores. These scores are
  # handled by a {ScoreRecorder}, which uses a {ScoreSet} to actually save the
  # scores. {ScoreSet} is also used to fetch the linkage scores so that a
  # {Matcher} can create matches.
  #
  # {ScoreSet} is the superclass of implementations for different formats.
  # Currently there are two formats for storing scores:
  #
  # * CSV ({ScoreSets::CSV})
  # * Database ({ScoreSets::Database})
  #
  # See the documentation for score set you're interested in for more
  # information.
  #
  # If you want to implement a custom {ScoreSet}, create a class that inherits
  # {ScoreSet} and defines at least {#add_score} and {#each_pair}. You can then
  # register that class via {.register}.
  #
  # @abstract
  class ScoreSet
    class << self
      # Register a new score set. Subclasses must define at least {#add_score}
      # and {#each_pair}. Otherwise, an `ArgumentError` will be raised when you
      # try to call {.register}.
      #
      # @param [String] name Score set name used in {.klass_for}
      # @param [Class] klass ScoreSet subclass
      def register(name, klass)
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

        @score_sets ||= {}
        @score_sets[name] = klass
      end

      # Return a registered ScoreSet subclass or `nil` if it doesn't exist.
      #
      # @param [String] name of registered score set
      # @return [Class, nil]
      def klass_for(name)
        @score_sets ? @score_sets[name] : nil
      end
      alias :[] :klass_for
    end

    # This is called by {Matcher#run}, before any scores are read via
    # {#each_pair}. Subclasses can redefine this to perform any setup needed
    # for reading scores.
    def open_for_reading
    end

    # This is called by {ScoreRecorder#start}, before any scores are added via
    # {#add_score}. Subclasses can redefine this to perform any setup needed
    # for saving scores.
    def open_for_writing
    end

    # Add a score to the ScoreSet. Subclasses must redefine this.
    #
    # @param comparator_id [Fixnum] 1-indexed comparator index
    # @param id_1 [Object] record id from first dataset
    # @param id_2 [Object] record id from second dataset
    # @param value [Fixnum, Float] score value
    # @abstract
    def add_score(comparator_id, id_1, id_2, value)
      raise NotImplementedError
    end

    # Yield scores for each pair of records. Subclasses must redefine this.
    # This method is called by {Matcher#run} with a block with three
    # parameters:
    #
    # ```ruby
    # score_set.each_pair do |id_1, id_2, scores|
    # end
    # ```
    #
    # `scores` should be a Hash where comparator ids are keys and scores are
    # values. For example: `{ 1 => 0.5, 2 => 0.75, 3 => 1 }`. Note that not all
    # comparators (including {Comparators::Compare}) create scores for each
    # pair. A missing score means that pair was given a score of 0.
    #
    # @abstract
    def each_pair(&block)
      raise NotImplementedError
    end

    # This is called by {ScoreRecorder#stop}, after all scores have been added.
    # Subclasses can redefine this to perform any teardown needed.
    def close
    end
  end
end

require 'linkage/score_sets/csv'
require 'linkage/score_sets/database'
