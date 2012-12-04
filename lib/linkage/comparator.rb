module Linkage
  # @abstract Abstract class to represent record comparators.
  class Comparator
    # Register a new comparator.
    #
    # @param [Class] klass Comparator subclass
    def self.register(klass)
      name = nil
      begin
        name = klass.comparator_name
      rescue NotImplementedError
        raise ArgumentError, "comparator_name class method must be defined"
      end

      if !klass.instance_methods(false).include?(:score)
        raise ArgumentError, "class must define the score method"
      end

      begin
        if klass.parameters.length > 0
          @comparators ||= {}
          @comparators[name] = klass
        else
          raise ArgumentError, "class must have at least one parameter"
        end
      rescue NotImplementedError
        raise ArgumentError, "parameters class method must be defined"
      end

      begin
        range = klass.score_range
        if !range.is_a?(Range) || !range.first.is_a?(Numeric) ||
              !range.last.is_a?(Numeric)
          raise ArgumentError, "score_range must be a Range of two numbers"
        end
      rescue NotImplementedError
        raise ArgumentError, "score_range class method must be defined"
      end
    end

    def self.[](name)
      @comparators ? @comparators[name] : nil
    end

    # @abstract Override this to return the name of the comparator.
    # @return [String]
    def self.comparator_name
      raise NotImplementedError
    end

    # @abstract Override this to require a specific number of arguments of a
    #   certain class. To require two parameters of either String or Integer,
    #   do something like this:
    #
    #     @@parameters = [[String, Integer], [String, Integer]]
    #     def self.parameters
    #       @@parameters
    #     end
    #
    #   At least one argument must be defined.
    # @return [Array]
    def self.parameters
      raise NotImplementedError
    end

    # @abstract Override this to return a Range of the possible scores for the
    #   comparator.
    # @return [Range]
    def self.score_range
      raise NotImplementedError
    end

    attr_reader :args

    # Create a new Comparator object.
    # @param [Linkage::MetaObject, Hash] args Comparator arguments
    def initialize(*args)
      @args = args
      @options = args.last.is_a?(Hash) ? args.pop : {}
      process_args
    end

    # @abstract Override this to return the score of the linkage strength of
    #   two records.
    # @return [Numeric]
    def score(record_1, record_2)
      raise NotImplementedError
    end

    private

    def process_args
      parameters = self.class.parameters
      if parameters.length != @args.length
        raise ArgumentError, "wrong number of arguments (#{@args.length} for #{parameters.length})"
      end

      @args.each_with_index do |arg, i|
        type = arg.ruby_type[:type]

        parameter_types = parameters[i]
        if parameter_types.last.is_a?(Hash)
          parameter_options = parameter_types[-1]
          parameter_types = parameter_types[0..-2]
        else
          parameter_options = {}
        end

        if parameter_types[0] != :any && !parameter_types.include?(type)
          raise TypeError, "expected type #{parameters[i].join(" or ")}, got #{type}"
        end

        if parameter_options.has_key?(:static) &&
              parameter_options[:static] != arg.static?
          raise TypeError, "argument #{i + 1} was expected to #{arg.static? ? "not be" : "be"} static"
        end
      end
    end
  end
end

Dir.glob(File.expand_path(File.join(File.dirname(__FILE__), "comparators", "*.rb"))).each do |filename|
  require filename
end
