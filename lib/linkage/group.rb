module Linkage
  class Group
    # @return [Hash] Hash of matching values
    attr_reader :values

    # @return [Integer] Number of records in this group
    attr_reader :count

    # @param [Hash] values Values that define this group, including the count
    # @example
    #   Linkage::Group.new({:foo => 123, :bar => 'baz', :count => 5})
    def initialize(values)
      @count = values.delete(:count)
      @values = values
    end
  end
end
