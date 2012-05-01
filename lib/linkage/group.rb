module Linkage
  class Group
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
    # @example
    #   Linkage::Group.new({:foo => 123, :bar => 'baz'}, {:count => 5, :id => 456})
    def initialize(values, options)
      @count = options[:count]
      @id = options[:id]
      @values = values
    end
  end
end
