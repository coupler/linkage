module Linkage
  class MetaObject
    attr_reader :object
    attr_writer :side

    # Creates a new MetaObject.
    #
    # @param [Object] object This can be a {Field}, {Function} or a regular
    #   Ruby object (Fixnum, String, etc). If `object` is not static (a {Field}
    #   or a {Function} that contains one or more {Field} objects), you should
    #   specify which "side" of the linkage the object belongs to (left-hand
    #   side or right-hand side) in the `side` argument.
    # @param [Symbol] side `:lhs` for left-hand side or `:rhs` for right-hand
    #   side
    def initialize(object, side = nil)
      @object = object
      @static = object.kind_of?(Linkage::Data) ? object.static? : true
      if !side.nil? && side != :lhs && side != :rhs
        raise ArgumentError, "invalid `side` argument, must be :lhs or :rhs"
      end
      @side = side
    end

    def side
      if !@static && @side.nil?
        raise RuntimeError, "Object is dynamic and side is not set"
      end
      @side
    end

    def dataset
      @object.kind_of?(Linkage::Data) ? @object.dataset : nil
    end

    def dataset=(dataset)
      if @object.kind_of?(Linkage::Data)
        @object.dataset = dataset
      else
        raise RuntimeError, "You can't set the dataset of a non-data object."
      end
    end

    def database_type
      ds = dataset
      ds ? ds.database_type : nil
    end

    def static?
      @static
    end

    # Returns true if the argument has the same object as the instance.
    #
    # @param [Linkage::MetaObject] other
    # @return [Boolean]
    def objects_equal?(other)
      other.is_a?(Linkage::MetaObject) && other.object == self.object
    end

    # Returns true if the argument has the same dataset as the instance.
    #
    # @param [Linkage::MetaObject] other
    # @return [Boolean]
    def datasets_equal?(other)
      other.is_a?(Linkage::MetaObject) && other.dataset == self.dataset
    end

    # Returns an expression suitable for use in Sequel queries.
    # @return [Object]
    def to_expr
      if @object.kind_of?(Linkage::Data)
        @object.to_expr
      else
        @object
      end
    end

    # Returns a Sequel identifier for {Data} objects, or the object itself.
    # @return [Sequel::SQL::Identifier, Object]
    def to_identifier
      if @object.kind_of?(Linkage::Data)
        Sequel::SQL::Identifier.new(@object.to_expr)
      else
        @object
      end
    end

    # Return the name of the object for {Data} objects, nil for others.
    # @return [Symbol, nil]
    def name
      if @object.kind_of?(Linkage::Data)
        @object.name
      else
        nil
      end
    end

    # Returns a {MergeField} if both objects are {Data} objects, otherwise,
    # raises an exception.
    #
    # @return [Linkage::MergeField]
    def merge(other)
      if @object.kind_of?(Linkage::Data) && other.object.kind_of?(Linkage::Data)
        @object.merge(other.object)
      else
        raise ArgumentError, "Cannot merge a non-data object"
      end
    end

    # Returns the Ruby type of the underlying object.
    #
    # @return [Hash]
    # @see Linkage::Field#ruby_type
    # @see Linkage::Function#ruby_type
    def ruby_type
      if @object.kind_of?(Linkage::Data)
        @object.ruby_type
      else
        {:type => @object.class}
      end
    end

    # Returns the collation of the underlying object.
    #
    # @return [Symbol]
    def collation
      if @object.kind_of?(Linkage::Data)
        @object.collation
      else
        nil
      end
    end

    # Returns true if underlying object is not a subclass of {Linkage::Data}.
    def raw?
      !@object.kind_of?(Linkage::Data)
    end
  end
end
