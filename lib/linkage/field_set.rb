module Linkage
  class FieldSet < Hash
    attr_reader :primary_key

    # Create a new FieldSet.
    #
    # @param [Linkage::Dataset] dataset
    def initialize(dataset)
      dataset.schema.each do |(name, column_schema)|
        f = Field.new(dataset, name, column_schema)
        self[name] = f

        if @primary_key.nil? && column_schema[:primary_key]
          @primary_key = f
        end
      end
    end

    def has_key?(key)
      !fetch_key(key).nil?
    end

    def fetch_key(key)
      string_key = key.to_s
      keys.detect { |k| k.to_s.casecmp(string_key) == 0 }
    end

    def [](key)
      k = fetch_key(key)
      k ? super(k) : nil
    end
  end
end
