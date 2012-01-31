module Linkage
  class FieldSet < Hash
    attr_reader :primary_key, :dataset

    def initialize(schema, dataset)
      @dataset = dataset

      schema.each_pair do |name, column_schema|
        f = Field.new(name, column_schema)
        f.dataset = dataset
        self[name] = f

        if @primary_key.nil? && column_schema[:primary_key]
          @primary_key = f
        end
      end
    end
  end
end
