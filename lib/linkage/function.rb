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

    # @param [Linkage::Field, Object] args Function arguments
    def initialize(*args)
      @names = [self.class.function_name]
      @args = args
      process_args
    end

    def name
      @name ||= @names.join("_").to_sym
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
    def to_expr(adapter = nil, options = {})
      self.class.function_name.to_sym.sql_function(*@values)
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
    end
  end
end

Dir.glob(File.expand_path(File.join(File.dirname(__FILE__), "functions", "*.rb"))).each do |filename|
  require filename
end
