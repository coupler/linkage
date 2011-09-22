module Linkage
  # A runner class that only uses a single thread to execute a linkage.
  #
  # @see Runner
  class SingleThreadedRunner < Runner
    def execute
      create_tables
      setup_datasets
      apply_expectations
      group_records
      nil
    end

    private

    def setup_datasets
      @dataset_1 = config.dataset_1.clone
      @dataset_2 = config.dataset_2.clone if @config.linkage_type != :self
    end

    def apply_expectations
      config.expectations.each do |exp|
        exp.apply_to(@dataset_1)
        exp.apply_to(@dataset_2) if config.linkage_type != :self
      end
    end

    def group_records
      add_groups(group_records_for(@dataset_1), 1)
      if config.linkage_type != :self
        add_groups(group_records_for(@dataset_2), 2)
        combine_groups
      end
    end

    def group_records_for(dataset, ignore_empty_groups = true)
      groups = []
      current_group = nil
      dataset.each do |row|
        if current_group.nil? || !current_group.matches?(row[:values])
          if current_group && (!ignore_empty_groups || current_group.count > 1)
            groups << current_group
          end
          new_group = Group.new(row[:values])
          current_group = new_group
        end
        current_group.add_record(row[:pk])
      end
      if current_group && (!ignore_empty_groups || current_group.count > 1)
        groups << current_group
      end
      groups
    end

    def add_groups(groups, dataset_id = nil)
      return if groups.empty?

      groups_headers = [:id] + groups[0].values.keys
      groups_buffer = ImportBuffer.new(@uri, :groups, groups_headers)

      groups_records_buffer = ImportBuffer.new(@uri, :groups_records, [:group_id, :dataset, :record_id])

      groups.each_with_index do |group, i|
        group_id = next_group_id
        groups_buffer.add([group_id] + group.values.values)
        group.records.each do |record_id|
          groups_records_buffer.add([group_id, dataset_id, record_id])
        end
      end
      groups_buffer.flush
      groups_records_buffer.flush
    end

    def combine_groups
      # Create a new dataset for the groups table
      ds = Dataset.new(@uri, :groups, :single_threaded => true)
      ds.fields.each_value do |field|
        # Sort on all fields
        next if field.primary_key?
        ds.add_order(field)
        ds.add_select(field)
      end
      ds.add_order(ds.primary_key) # ensure matching groups are sorted by id
      combined_groups = group_records_for(ds, false)
      combined_groups.each do |group|
        database do |db|
          groups_to_delete = []
          if group.count == 1
            # Delete the empty group
            groups_to_delete << group.records[0]
          else
            # Change group_id in the groups_records table to the first group
            # id, delete other groups.
            new_group_id = group.records[0]
            group.records[1..-1].each do |old_group_id|
              # There can only be a group with max size of 2, but this
              # adds in future support for matching more than 2 datasets
              # at once. Code smell?
              db[:groups_records].filter(:group_id => old_group_id).
                update(:group_id => new_group_id)
              groups_to_delete << old_group_id
            end
          end
          db[:groups_records].filter(:group_id => groups_to_delete).delete
          db[:groups].filter(:id => groups_to_delete).delete
        end
      end
    end
  end
end
