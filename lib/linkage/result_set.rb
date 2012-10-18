module Linkage
  class ResultSet
    def initialize(config)
      @config = config
      @next_group_id = 1
      @next_group_mutex = Mutex.new
    end

    def groups_dataset
      @groups_dataset ||= Dataset.new(@config.results_uri, :groups, @config.results_uri_options)
    end

    def database(&block)
      Sequel.connect(@config.results_uri, @config.results_uri_options, &block)
    end

    def create_tables!
      database do |db|
        schema = @config.groups_table_schema
        db.create_table(:original_groups) do
          schema.each { |col| column(*col) }
        end

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
      original_values = group.values
      values = group.decollated_values
      if !@groups_buffer
        groups_headers = [:id] + values.keys
        @groups_buffer = ImportBuffer.new(@config.results_uri, :groups, groups_headers, @config.results_uri_options)

        original_groups_headers = [:id] + original_values.keys
        @original_groups_buffer = ImportBuffer.new(@config.results_uri, :original_groups, original_groups_headers, @config.results_uri_options)
      end

      group_id = next_group_id
      @groups_buffer.add([group_id] + values.values)
      @original_groups_buffer.add([group_id] + original_values.values)
    end

    def flush!
      @groups_buffer.flush if @groups_buffer
    end

    def get_group(index)
      values = groups_dataset.order(:id).limit(1, index).first
      Group.from_row(values)
    end

    def groups_records_datasets(group)
      datasets = @config.datasets_with_applied_expectations
      datasets.collect! { |ds| ds.dataset_for_group(group) }
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
