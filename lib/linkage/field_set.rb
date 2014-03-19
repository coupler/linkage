module Linkage
  # {FieldSet} is a `Hash` of {Field} values. It is usually associated with a
  # {Dataset}. It looks up keys in a case-insensitive manner and doesn't care if
  # you use strings or symbols.
  #
  # @see Dataset#field_set
  class FieldSet < Hash
    # @return [Field] primary key of this field set.
    attr_reader :primary_key

    # Create a new FieldSet.
    #
    # @param [Linkage::Dataset] dataset
    def initialize(dataset)
      dataset.schema.each do |(name, column_schema)|
        field = Field.new(name, column_schema)
        self[name] = field

        if @primary_key.nil? && column_schema[:primary_key]
          @primary_key = field
        end
      end
    end

    # Returns whether or not `key` is contained in the field set
    # (case-insensitive).
    #
    # @param key [String, Symbol]
    # @return [Boolean]
    def has_key?(key)
      !fetch_key(key).nil?
    end

    # Returns a key that matches the parameter in a case-insensitive manner.
    #
    # @param key [String, Symbol]
    # @return [Symbol]
    def fetch_key(key)
      string_key = key.to_s
      keys.detect { |k| k.to_s.casecmp(string_key) == 0 }
    end

    # Returns the value for `key`, where `key` is matched in a case-insensitive
    # manner.
    #
    # @param key [String, Symbol]
    # @return [Field]
    def [](key)
      k = fetch_key(key)
      k ? super(k) : nil
    end
  end
end
