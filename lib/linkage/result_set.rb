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
        if @config.groups_table_needed?
          schema = @config.groups_table_schema
          if @config.decollation_needed?
            db.create_table(:original_groups) do
              schema.each { |col| column(*col) }
            end
          end

          db.create_table(:groups) do
            schema.each { |col| column(*col) }
          end
        end

        if @config.scores_table_needed?
          schema = @config.scores_table_schema
          db.create_table(:scores) do
            schema.each { |col| column(*col) }
          end
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
      if @config.decollation_needed?
        original_values = group.values
        values = group.decollated_values
        if !@groups_buffer
          groups_headers = [:id] + values.keys
          @groups_buffer = ImportBuffer.new(database[:groups], groups_headers)

          original_groups_headers = [:id] + original_values.keys
          @original_groups_buffer = ImportBuffer.new(database[:original_groups], original_groups_headers)
        end

        group_id = next_group_id
        @groups_buffer.add([group_id] + values.values)
        @original_groups_buffer.add([group_id] + original_values.values)
      else
        # Non-DRY for minute speed improvements
        values = group.values
        if !@groups_buffer
          groups_headers = [:id] + values.keys
          @groups_buffer = ImportBuffer.new(database[:groups], groups_headers)
        end
        group_id = next_group_id
        @groups_buffer.add([group_id] + values.values)
      end
    end

    def add_score(comparator_id, record_1_id, record_2_id, score)
      if !@scores_buffer
        scores_headers = [:comparator_id, :record_1_id, :record_2_id, :score]
        @scores_buffer = ImportBuffer.new(database[:scores], scores_headers)
      end
      @scores_buffer.add([comparator_id, record_1_id, record_2_id, score])
    end

    def flush!
      @groups_buffer.flush if @groups_buffer
      @scores_buffer.flush if @scores_buffer
    end

    def get_group(index)
      values = groups_dataset.order(:id).limit(1, index).first
      Group.from_row(values)
    end

    def groups_records_datasets(group)
      datasets = @config.datasets_with_applied_simple_expectations
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
