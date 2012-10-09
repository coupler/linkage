module Linkage
  class Group
    include Linkage::Decollation

    # @return [Hash] Hash of matching values
    attr_reader :values

    # @return [Integer] Number of records in this group
    attr_reader :count

    # @return [Integer] This group's ID (if it exists)
    attr_reader :id

    def self.from_row(row)
      values = {}
      options = {}
      row.each_pair do |key, value|
        if key == :id || key == :count
          options[key] = value
        else
          values[key] = value
        end
      end
      new(values, options)
    end

    # @param [Hash] values Values that define this group
    # @param [Hash] options
    # @option options [Fixnum] :id The group ID
    # @option options [Fixnum] :count How many records are in the group
    # @option options [Hash] :ruby_types Hash of ruby types for each value
    # @option options [Symbol] :database_type
    # @example
    #   Linkage::Group.new({:foo => 123, :bar => 'baz'}, {:count => 5, :id => 456})
    def initialize(values, options)
      @count = options[:count]
      @id = options[:id]
      @ruby_types = options[:ruby_types]
      @database_type = options[:database_type]
      @values = values
    end

    def decollated_values
      @values.inject({}) do |hsh, (key, value)|
        ruby_type = @ruby_types[key]
        if ruby_type && ruby_type.has_key?(:opts) && ruby_type[:opts].has_key?(:collate)
          hsh[key] = decollate(value, @database_type, ruby_type[:opts][:collate])
        else
          hsh[key] = value
        end
        hsh
      end
    end
  end
end
