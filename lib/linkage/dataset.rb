module Linkage
  # {Dataset} is a representation of a database table. It is a thin wrapper
  # around a
  # {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Dataset.html `Sequel::Dataset`}.
  #
  # There are three ways to create a {Dataset}.
  #
  # Pass in a {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Dataset.html `Sequel::Dataset`}:
  #
  # ```ruby
  # Linkage::Dataset.new(db[:foo])
  # ```
  #
  # Pass in a {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Database.html `Sequel::Database`}
  # and a table name:
  #
  # ```ruby
  # Linkage::Dataset.new(db, :foo)
  # ```
  #
  # Pass in a
  # {http://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html Sequel-style}
  # connection URI, a table name, and any options you want to pass to
  # {http://sequel.jeremyevans.net/rdoc/classes/Sequel.html#method-c-connect `Sequel.connect`}.
  #
  # ```ruby
  # Linkage::Dataset.new("mysql2://example.com/foo", :bar, :user => 'viking', :password => 'secret')
  # ```
  #
  # Once you've made a {Dataset}, you can use any
  # {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Dataset.html `Sequel::Dataset`}
  # method on it you wish. For example, if you want to limit the dataset to
  # records that refer to people born after 1985 (assuming date of birth is
  # stored as a date type):
  #
  # ```ruby
  # filtered_dataset = dataset.where('dob > :date', :date => Date.new(1985, 1, 1))
  # ```
  #
  # Note that
  # {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Dataset.html `Sequel::Dataset`}
  # methods return a __clone__ of a dataset, so you must assign the return value
  # to a variable.
  #
  # Once you have your {Dataset} how you want it, you can use the {#link_with}
  # method to create a {Configuration} for record linkage. The {#link_with}
  # method takes another {Dataset} object and a {ResultSet} and returns a
  # {Configuration}.
  #
  # ```ruby
  # config = dataset.link_with(other_dataset, result_set)
  # config.compare([:foo], [:bar], :equal_to)
  # ```
  #
  # Note that a dataset can be linked with itself the same way, like so:
  #
  # ```ruby
  # config = dataset.link_with(dataset, result_set)
  # config.compare([:foo], [:bar], :equal_to)
  # ```
  #
  # If you give {#link_with} a block, it will yield the same {Configuration}
  # object to the block that it returns.
  #
  # ```ruby
  # config = dataset.link_with(other_dataset, result_set) do |c|
  #   c.compare([:foo], [:bar], :equal_to)
  # end
  # ```
  #
  # Once that's done, use a {Runner} to run the record linkage:
  #
  # ```ruby
  # runner = Linkage::Runner.new(config)
  # runner.execute
  # ```
  #
  # @see http://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html Connecting to a database
  class Dataset
    # @return [Symbol] Returns this dataset's table name.
    attr_reader :table_name

    # @return [FieldSet] Returns this dataset's {FieldSet}.
    attr_reader :field_set

    # Returns a new instance of {Dataset}.
    #
    # @overload initialize(dataset)
    #   Use a specific {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Dataset.html `Sequel::Dataset`}.
    #   @param dataset [Sequel::Dataset]
    # @overload initialize(database, table_name)
    #   Use a specific {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Database.html `Sequel::Database`}.
    #   @param database [Sequel::Database]
    #   @param table_name [Symbol, String]
    # @overload initialize(uri, table_name, options = {})
    #   Use {http://sequel.jeremyevans.net/rdoc/classes/Sequel.html#method-c-connect `Sequel.connect`}
    #   to connect to a database.
    #   @param uri [String, Hash]
    #   @param table_name [Symbol, String]
    #   @param options [Hash]
    #
    def initialize(*args)
      if args.length == 0 || args.length > 3
        raise ArgumentError, "wrong number of arguments (#{args.length} for 1..3)"
      end

      if args.length == 1
        unless args[0].kind_of?(Sequel::Dataset)
          raise ArgumentError, "expected Sequel::Dataset, got #{args[0].class}"
        end

        @dataset = args[0]
        @db = @dataset.db
        @table_name = @dataset.first_source_table
      elsif args.length == 2 && args[0].kind_of?(Sequel::Database)
        @db = args[0]
        @table_name = args[1].to_sym
        @dataset = @db[@table_name]
      else
        uri, table_name, options = args
        options ||= {}

        @db = Sequel.connect(uri, options)
        @table_name = table_name.to_sym
        @dataset = @db[@table_name]
      end
      @field_set = FieldSet.new(self)
    end

    # Returns the underlying {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Dataset.html `Sequel::Dataset`}.
    # @return [Sequel::Dataset]
    def obj
      @dataset
    end

    # Set the underlying {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Dataset.html `Sequel::Dataset`}.
    def obj=(value)
      @dataset = value
    end
    private :obj=

    # Create a {Configuration} for record linkage.
    #
    # @param dataset [Dataset]
    # @param result_set [ResultSet]
    # @return [Configuration]
    def link_with(dataset, result_set)
      other = dataset.eql?(self) ? nil : dataset
      conf = Configuration.new(self, other, result_set)
      if block_given?
        yield conf
      end
      conf
    end

    # Return the dataset's schema.
    #
    # @return [Array]
    # @see http://sequel.jeremyevans.net/rdoc/classes/Sequel/Database.html#method-i-schema Sequel::Database#schema
    def schema
      @db.schema(@table_name)
    end

    # Returns {FieldSet#primary_key}.
    #
    # @return [Field]
    # @see FieldSet#primary_key
    def primary_key
      @field_set.primary_key
    end

    protected

    # Delegate methods to the underlying
    # {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Dataset.html `Sequel::Dataset`}.
    def method_missing(name, *args, &block)
      result = @dataset.send(name, *args, &block)
      if result.kind_of?(Sequel::Dataset)
        new_object = clone
        new_object.send(:obj=, result)
        new_object
      else
        result
      end
    end
  end
end
