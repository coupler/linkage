module Linkage
  # Wrapper for a Sequel dataset
  class Dataset
    @@next_id = 1 # Internal ID used for expectations
    @@next_id_mutex = Mutex.new

    # @private
    def self.next_id
      result = nil
      @@next_id_mutex.synchronize do
        result = @@next_id
        @@next_id += 1
      end
      result
    end

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

    # @private
    attr_reader :id

    # @param [String] uri Sequel-style database URI
    # @param [String, Symbol] table Database table name
    # @param [Hash] options Options to pass to Sequel.connect
    # @see http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html Sequel: Connecting to a database
    def initialize(uri, table, options = {})
      @id = self.class.next_id
      @uri = uri
      @table = table.to_sym
      @options = options
      schema = nil
      database { |db| schema = db.schema(@table) }
      @schema = schema
      @order = []
      @select = []
      @filter = []
      create_fields
    end

    # Setup a linkage with another dataset
    #
    # @return [Linkage::Configuration]
    def link_with(dataset, &block)
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
      other = self.class.allocate
      other.send(:initialize_copy, self, {
        :order => @order.clone, :select => @select.clone,
        :filter => @filter.clone, :options => @options.clone
      })
    end

    # Add a field to use for ordering the dataset.
    #
    # @param [Linkage::Field] field
    # @param [nil, Symbol] desc nil or :desc (for descending order)
    def add_order(field, desc = nil)
      @order << (desc == :desc ? field.name.desc : field.name)
    end

    # Add a field to be selected on the dataset. If you don't add any
    # selects, all fields will be selected. The primary key is always
    # selected in either case.
    #
    # @param [Linkage::Field] field
    # @param [Symbol] as Optional field alias
    def add_select(field, as = nil)
      @select << (as ? field.name.as(as) : field.name)
    end

    # Add a filter (SQL WHERE) condition to the dataset.
    #
    # @param [Linkage::Field] field
    # @param [Symbol] operator
    # @param [Linkage::Field, Object] other
    def add_filter(field, operator, other)
      arg1 = field.name
      arg2 = other.is_a?(Field) ? other.name : other
      expr =
        case operator
        when :==
          { arg1 => arg2 }
        when :'!='
          ~{ arg1 => arg2 }
        else
          arg1 = Sequel::SQL::Identifier.new(arg1)
          arg2 = arg2.is_a?(Symbol) ? Sequel::SQL::Identifier.new(arg2) : arg2
          Sequel::SQL::BooleanExpression.new(operator, arg1, arg2)
        end
      @filter << expr
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
          ds = ds.select(pk, *@select)
        end
        if !@order.empty?
          ds = ds.order(*@order)
        end
        if !@filter.empty?
          ds = ds.filter(*@filter)
        end
        ds.each do |row|
          yield({:pk => row.delete(pk), :values => row})
        end
      end
    end

    private

    def initialize_copy(dataset, options = {})
      @id = dataset.id
      @uri = dataset.uri
      @table = dataset.table
      @schema = dataset.schema
      @options = options[:options]
      @order = options[:order]
      @select = options[:select]
      @filter = options[:filter]
      @fields = dataset.fields.inject({}) do |hsh, (name, field)|
        new_field = field.clone
        new_field.dataset = self
        hsh[name] = new_field
        hsh
      end
      @primary_key = @fields[dataset.primary_key.name]
      self
    end

    def database(&block)
      Sequel.connect(uri, @options, &block)
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

    def set_new_id
      @id = self.class.next_id
    end
  end
end
