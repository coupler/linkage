module Linkage
  # This class represents a group of records that match based on criteria
  # described via the {Dataset#link_with} method. Group's are created by
  # subclasses of the {Runner} class during execution.
  #
  # @see Dataset#link_with
  # @see SingleThreadedRunner
  class Group
    # @return [Array<Object>] An array of this group's record ids
    attr_reader :records

    # @return [Hash] Hash of matching values
    attr_reader :values

    # @param [Hash] matching_values Values that define this group
    # @example
    #   Linkage::Group.new({:foo => 123, :bar => 'baz'})
    def initialize(matching_values)
      @values = matching_values
      @records = []
    end

    # Check to see if the given set of values matches this group's values.
    #
    # @param [Hash] values Hash of values
    # @return [Boolean] true if match, false if not
    def matches?(values)
      @values == values
    end

    # Add a record id to this group's set of records.
    #
    # @param [Object] record_id
    def add_record(record_id)
      @records << record_id
    end

    # @return [Fixnum] Number of records in this group
    def count
      @records.count
    end
  end
end
