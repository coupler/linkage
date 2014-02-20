module Linkage
  # Comparator is the superclass for comparators in Linkage. Comparators are
  # used
  # @abstract
  class Comparator
    include Observable

    class << self
      # Register a new comparator.
      #
      # @param [String] name Comparator name used in {Comparator.klass_for}
      # @param [Class] klass Comparator subclass
      def register(name, klass)
        methods = klass.instance_methods(false)
        if !methods.include?(:score) && (!methods.include?(:score_datasets) || !methods.include?(:score_dataset))
          raise ArgumentError, "class must define either #score or both #score_datasets and #score_dataset methods"
        end

        @comparators ||= {}
        @comparators[name] = klass
      end

      # Return a registered Comparator subclass or nil if it doesn't exist.
      #
      # @param [String] name of registered comparator
      # @return [Class, nil]
      def klass_for(name)
        @comparators ? @comparators[name] : nil
      end
      alias :[] :klass_for
    end

    # Return the type of this comparator.
    #
    # @return [Symbol] either `:simple` or `:advanced`
    def type
      @type || :simple
    end

    # Override this to return the score of the linkage strength of two records.
    #
    # @abstract
    # @param [Hash] record_1 data from first record
    # @param [Hash] record_2 data from second record
    # @return [Numeric] value between 0 and 1 (inclusive)
    def score(record_1, record_2)
      raise NotImplementedError
    end

    # Calls {#score} with two hashes of record data. The result is then used to
    # notify any observers.
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
