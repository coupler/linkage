module Linkage
  class ResultSet
    def initialize(config)
      @config = config
      @next_group_id = 1
      @next_group_mutex = Mutex.new
    end

    def groups_dataset
      Dataset.new(@config.results_uri, :groups, @config.results_uri_options)
    end

    def groups_records_dataset
      Dataset.new(@config.results_uri, :groups_records, @config.results_uri_options)
    end

    def database(&block)
      Sequel.connect(@config.results_uri, @config.results_uri_options, &block)
    end

    def create_tables!
      database do |db|
        schema = @config.groups_table_schema
        db.create_table(:groups) do
          schema.each { |col| column(*col) }
        end

        pk_type = @config.dataset_1.field_set.primary_key.merge(@config.dataset_2.field_set.primary_key).ruby_type
        db.create_table(:groups_records) do
          column(:record_id, pk_type[:type], pk_type[:opts] || {})
          Integer :group_id
          Integer :dataset
          index :group_id
        end
      end
    end

    def add_group(group, dataset_id = nil)
      if !@groups_buffer
        groups_headers = [:id] + group.values.keys
        @groups_buffer = ImportBuffer.new(@config.results_uri, :groups, groups_headers, @config.results_uri_options)
      end
      @groups_records_buffer ||= ImportBuffer.new(@config.results_uri, :groups_records, [:group_id, :dataset, :record_id], @config.results_uri_options)

      group_id = next_group_id
      @groups_buffer.add([group_id] + group.values.values)
      group.records.each do |record_id|
        @groups_records_buffer.add([group_id, dataset_id, record_id])
      end
    end

    def flush!
      @groups_buffer.flush if @groups_buffer
      @groups_records_buffer.flush if @groups_records_buffer
    end

    private

    def next_group_id
      result = nil
      @next_group_mutex.synchronize do
        result = @next_group_id
        @next_group_id += 1
      end
      result
    end
  end
end
