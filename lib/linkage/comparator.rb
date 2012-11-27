module Linkage
  # Abstract class to represent record comparators.
  #
  # @abstract
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
    end

    def self.[](name)
      @comparators ? @comparators[name] : nil
    end

    # Subclasses must define this.
    def self.comparator_name
      raise NotImplementedError
    end

    # Subclasses must define this to require a specific number of arguments
    # of a certain class. To require two parameters of either String or
    # Integer, do something like this:
    #
    #   @@parameters = [[String, Integer], [String, Integer]]
    #   def self.parameters
    #     @@parameters
    #   end
    #
    # At least one argument must be defined.
    def self.parameters
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

    def score(record_1, record_2)
      raise NotImplementedError
    end

    private

    def process_args
      parameters = self.class.parameters
      if parameters && parameters.length != @args.length
        raise ArgumentError, "wrong number of arguments (#{@args.length} for #{parameters.length})"
      end

      @args.each_with_index do |arg, i|
        type = arg.ruby_type[:type]
        if parameters && parameters[i] != [:any] && !parameters[i].include?(type)
          raise TypeError, "expected type #{parameters[i].join(" or ")}, got #{type}"
        end
        if i == 0 && arg.static?
          raise TypeError, "first argument must not be static"
        end
      end
    end
  end
end

Dir.glob(File.expand_path(File.join(File.dirname(__FILE__), "comparators", "*.rb"))).each do |filename|
  require filename
end
