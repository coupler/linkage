module Linkage
  class FieldSet < Hash
    attr_reader :primary_key

    def initialize(schema)
      schema.each do |(name, column_schema)|
        f = Field.new(name, column_schema)
        self[name] = f

        if @primary_key.nil? && column_schema[:primary_key]
          @primary_key = f
        end
      end
    end
  end
end
