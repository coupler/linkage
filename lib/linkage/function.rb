module Linkage
  # Abstract class to represent SQL functions. No attempts are made to
  # ensure that the function actually exists in the database you're using.
  #
  # @abstract
  class Function < Data
    # Register a new function.
    #
    # @param [Class] klass Function class (probably a subclass of {Function})
    def self.register(klass)
      if klass.instance_methods(false).any? { |m| m.to_s == "ruby_type" }
        @functions ||= {}
        @functions[klass.function_name] = klass
      else
        raise ArgumentError, "ruby_type instance method must be defined"
      end
    end

    def self.[](name)
      @functions ? @functions[name] : nil
    end

    # Subclasses must define this.
    def self.function_name
      raise NotImplementedError
    end

    # Subclasses can define this to require a specific number of arguments
    # of a certain class. To require two parameters of either String or
    # Integer, do something like this:
    #
    #   @@parameters = [[String, Integer], [String, Integer]]
    #   def self.parameters
    #     @@parameters
    #   end
    #
    def self.parameters
      nil
    end

    # Creates a new Function object. If the arguments contain only
    # static objects, you should specify the dataset that this function
    # belongs to as the last argument like so:
    #
    #   Function.new(foo, bar, :dataset => dataset)
    #
    # Optionally, you can use the `dataset=` setter to do it later. Many
    # functions require a dataset to work properly. If you try to use
    # such a function without setting a  dataset, it will raise a RuntimeError.
    #
    # @param [Linkage::Data, Object] args Function arguments
    def initialize(*args)
      @names = [self.class.function_name]
      @args = args
      @options = args.last.is_a?(Hash) ? args.pop : {}
      process_args
    end

    def name
      @name ||= @names.join("_").to_sym
    end

    def dataset=(dataset)
      @dataset = dataset
    end

    def static?
      @static
    end

    # Subclasses must define this. The return value should be a Hash with
    # the following elements:
    #   :type - column type (Ruby class) of the result
    #   :opts - Optional hash with additional options (like :size)
    def ruby_type
      raise NotImplementedError
    end

    # @return [Sequel::SQL::Function]
    def to_expr(options = {})
      self.class.function_name.to_sym.sql_function(*@values)
    end

    protected

    def assert_dataset
      if @dataset.nil?
        raise RuntimeError, "You must specify a dataset for static functions"
      end
    end

    private

    def process_args
      parameters = self.class.parameters
      if parameters && parameters.length != @args.length
        raise ArgumentError, "wrong number of arguments (#{@args.length} for #{parameters.length})"
      end

      @static = true
      @values = []
      @args.each_with_index do |arg, i|
        if arg.kind_of?(Data)
          @names << arg.name
          @static &&= arg.static?

          # possibly set dataset
          if @dataset.nil?
            @dataset = arg.dataset
          elsif @dataset != arg.dataset
            raise ArgumentError, "Using dynamic data sources with different datasets is not permitted"
          end

          type = arg.ruby_type[:type]
          value = arg.to_expr
        else
          @names << arg.to_s.gsub(/\W/, "")
          type = arg.class
          value = arg
        end
        if parameters && !parameters[i].include?(type)
          raise TypeError, "expected type #{parameters[i].join(" or ")}, got #{type}"
        end
        @values << value
      end

      if @dataset.nil? && @options[:dataset]
        # Set dataset for static functions manually
        @dataset = @options[:dataset]
      end
    end
  end
end

Dir.glob(File.expand_path(File.join(File.dirname(__FILE__), "functions", "*.rb"))).each do |filename|
  require filename
end
