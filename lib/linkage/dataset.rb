module Linkage
  # Wrapper for a Sequel dataset
  class Dataset
    # @return [Array] Schema information about the dataset's primary key
    attr_reader :primary_key

    # @return [Array] Schema information for this dataset
    attr_reader :schema

    # @return [String] Database URI
    attr_reader :uri

    # @return [Symbol] Database table name
    attr_reader :table

    # @return [Array<Linkage::Field>] List of {Linkage::Field}'s
    attr_reader :fields

    # @param [String] uri Sequel-style database URI
    # @param [String, Symbol] table Database table name
    # @see http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html Sequel: Connecting to a database
    def initialize(uri, table)
      @uri = uri
      @table = table.to_sym
      schema = nil
      database { |db| schema = db.schema(@table) }
      @schema = schema
      @order = []
      @select = []
      create_fields
    end

    # Setup a linkage with another dataset
    #
    # @return [Linkage::Configuration]
    def link_with(dataset, &block)
      if dataset.equal?(self)
        dataset = clone
      end
      conf = Configuration.new(self, dataset)
      conf.instance_eval(&block)
      conf
    end

    # Compare URI and database table name
    #
    # @return [Boolean]
    def ==(other)
      if !other.is_a?(Dataset)
        super
      else
        uri == other.uri && table == other.table
      end
    end

    # Create a copy of this instance of Dataset, using {Dataset#initialize}.
    #
    # @return [Linkage::Dataset]
    def dup
      self.class.new(uri, table)
    end

    # Clone the dataset and its associated {Linkage::Field}'s (without hitting
    # the database).
    #
    # @return [Linkage::Dataset]
    def clone
      other = super
      other_fields = other.fields.inject({}) do |hsh, (name, field)| 
        new_field = field.clone
        new_field.dataset = other
        hsh[name] = new_field
        hsh
      end
      other.instance_variable_set(:@fields, other_fields)
      other
    end

    # Add a field to use for ordering the dataset.
    #
    # @param [Linkage::Field] field
    def add_order(field)
      @order << field
    end

    # Add a field to be selected on the dataset. If you don't add any
    # selects, all fields will be selected. The primary key is always
    # selected in either case.
    #
    # @param [Linkage::Field] field
    def add_select(field)
      @select << field
    end

    # Yield each row of the dataset in a block.
    #
    # @yield [row] A Hash of two elements, :pk and :values, where row[:pk] is
    #   the row's primary key value, and row[:values] is an array of all
    #   selected values (except the primary key).
    def each
      database do |db|
        ds = db[@table]

        pk = @primary_key.name
        if !@select.empty?
          ds = ds.select(pk, *@select.collect(&:name))
        end
        if !@order.empty?
          ds = ds.order(*@order.collect(&:name))
        end
        ds.each do |row|
          yield({:pk => row.delete(pk), :values => row})
        end
      end
    end

    private

    def database(&block)
      Sequel.connect(uri, &block)
    end

    def create_fields
      @fields = {}
      @schema.each do |(name, column_schema)|
        f = Field.new(name, column_schema)
        f.dataset = self
        @fields[name] = f

        if @primary_key.nil? && column_schema[:primary_key]
          @primary_key = f
        end
      end
    end
  end
end
