module Linkage
  # {Comparator} is the superclass for comparators in Linkage. Comparators are
  # used to compare two records and compute scores based on how closely the two
  # records relate.
  #
  # Each comparator should inherit from {Comparator} and declare itself as
  # simple or advanced by overriding {#type} (the default is simple). Simple
  # comparators must define the {#score} method that uses data from two records
  # and returns a number (`Integer` or `Float`) between 0 and 1 (inclusive).
  # Advanced comparators must define both {#score_dataset} and {#score_datasets}
  # that use one or two {Dataset}s respectively to create scores.
  #
  # Each comparator can be registered via the {.register} function. This allows
  # {Configuration} a way to find a comparator by name via
  # {Configuration#method_missing}. For example, `config.compare(...)` creates a
  # new {Comparators::Compare} object, since that comparator is registered under
  # the name `"compare"`.
  #
  # See documentation for the methods below for more information.
  #
  # @abstract
  class Comparator
    include Observable

    class << self
      # Register a new comparator. Subclasses must define at least {#score} for
      # simple comparators, or {#score_dataset} and {#score_datasets} for
      # advanced comparators. Otherwise, an `ArgumentError` will be raised when
      # you try to call {.register}. The `name` parameter is used in
      # {Configuration#method_missing} as an easy way for users to select
      # comparators for their linkage.
      #
      # @param [String] name Comparator name used in {.klass_for}
      # @param [Class] klass Comparator subclass
      def register(name, klass)
        methods = klass.instance_methods(false)
        if !methods.include?(:score) && (!methods.include?(:score_datasets) || !methods.include?(:score_dataset))
          raise ArgumentError, "class must define either #score or both #score_datasets and #score_dataset methods"
        end

        @comparators ||= {}
        @comparators[name] = klass
      end

      # Return a registered Comparator subclass or `nil` if it doesn't exist.
      #
      # @param [String] name of registered comparator
      # @return [Class, nil]
      def klass_for(name)
        @comparators ? @comparators[name] : nil
      end
      alias :[] :klass_for
    end

    # Return the type of this comparator. When {#type} returns `:simple`,
    # {#score_and_notify} is called by {Runner#score_records} with each pair of
    # records in order to create scores. When {#type} returns `:advanced`,
    # either {#score_dataset} or {#score_datasets} is called by
    # {Runner#score_records}. In advanced mode, it is left up to the
    # {Comparator} subclass to determine which records to compare and how to
    # compare them.
    #
    # @return [Symbol] either `:simple` or `:advanced`
    def type
      @type || :simple
    end

    # Override this to return the score of the linkage strength of two records.
    # This method is used to score records by {Runner#score_records} when
    # {#type} returns `:simple`.
    #
    # @abstract
    # @param [Hash] record_1 data from first record
    # @param [Hash] record_2 data from second record
    # @return [Numeric] value between 0 and 1 (inclusive)
    def score(record_1, record_2)
      raise NotImplementedError
    end

    # Override this to score the linkage strength of records in two datasets.
    # This method is used to score records by {Runner#score_records} when
    # {#type} returns `:advanced` and {Configuration} is setup to link two
    # datasets together.
    #
    # Since each {Dataset} delegates to a
    # {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Dataset.html `Sequel::Dataset`},
    # you can use any
    # {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Dataset.html `Sequel::Dataset`}
    # methods that you wish in order to select records to compare.
    #
    # To record scores, subclasses must call
    # {http://ruby-doc.org/stdlib/libdoc/observer/rdoc/Observable.html `Observable#notify_observers`}
    # like so:
    #
    # ```ruby
    # changed
    # notify_observers(self, record_1, record_2, score)
    # ```
    #
    # This works by notifying any observers, typically {ScoreRecorder}, that a
    # new score has been generated. {ScoreRecorder#update} then calls
    # {ScoreSet#add_score} with comparator ID, the primary key of each record
    # and the score.
    #
    # @abstract
    # @param [Linkage::Dataset] dataset_1
    # @param [Linkage::Dataset] dataset_2
    # @see http://ruby-doc.org/stdlib/libdoc/observer/rdoc/Observable.html Observable
    # @see http://sequel.jeremyevans.net/rdoc/classes/Sequel/Dataset.html Sequel::Dataset
    def score_datasets(dataset_1, dataset_2)
      raise NotImplementedError
    end

    # Override this to score the linkage strength of records in one dataset.
    # This method is used to score records by {Runner#score_records} when
    # {#type} returns `:advanced` and {Configuration} is setup to link a
    # dataset to itself.
    #
    # Since a {Dataset} delegates to a
    # {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Dataset.html `Sequel::Dataset`},
    # you can use any
    # {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Dataset.html `Sequel::Dataset`}
    # methods that you wish in order to select records to compare.
    #
    # To record scores, subclasses must call
    # {http://ruby-doc.org/stdlib/libdoc/observer/rdoc/Observable.html `Observable#notify_observers`}
    # like so:
    #
    # ```ruby
    # changed
    # notify_observers(self, record_1, record_2, score)
    # ```
    #
    # This works by notifying any observers, typically {ScoreRecorder}, that a
    # new score has been generated.  {ScoreRecorder#update} then calls
    # {ScoreSet#add_score} with comparator ID, the primary key of each record
    # and the score.
    #
    # @abstract
    # @param [Linkage::Dataset] dataset
    # @see http://ruby-doc.org/stdlib/libdoc/observer/rdoc/Observable.html Observable
    # @see http://sequel.jeremyevans.net/rdoc/classes/Sequel/Dataset.html Sequel::Dataset
    def score_dataset(dataset)
      raise NotImplementedError
    end

    # Calls {#score} with two hashes of record data. The result is then used to
    # notify any observers (typically {ScoreRecorder}).
    #
    # This method is used by {Runner#score_records} when {#type} returns
    # `:simple`. Subclasses should override {#score} to implement the scoring
    # algorithm.
    #
    # @param [Hash] record_1 data from first record
    # @param [Hash] record_2 data from second record
    def score_and_notify(record_1, record_2)
      value = score(record_1, record_2)
      changed
      notify_observers(self, record_1, record_2, value)
    end
  end
end

path = File.expand_path(File.join(File.dirname(__FILE__), "comparators"))
require File.join(path, "compare")
require File.join(path, "within")
require File.join(path, "strcompare")
