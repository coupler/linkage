module Linkage
  # A runner class that only uses a single thread to execute a linkage.
  #
  # @see Runner
  class SingleThreadedRunner < Runner
    def execute
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
      result_set.create_tables!

      if config.linkage_type == :self
        group_records_for(@dataset_1, 1)
      else
        group_records_for(@dataset_1, 1, false)
        group_records_for(@dataset_2, 2, false)
        combine_groups
      end
    end

    # @param [Linkage::Dataset] dataset
    # @param [Fixnum, nil] dataset_id
    # @param [Boolean] ignore_empty_groups
    # @yield [Linkage::Group] If a block is given, yield completed groups to
    #   the block. Otherwise, call ResultSet#add_group on the group.
    def group_records_for(dataset, dataset_id = nil, ignore_empty_groups = true, &block)
      current_group = nil
      block ||= lambda { |group| result_set.add_group(current_group, dataset_id) }
      dataset.each do |row|
        if current_group.nil? || !current_group.matches?(row[:values])
          if current_group && (!ignore_empty_groups || current_group.count > 1)
            block.call(current_group)
          end
          new_group = Group.new(row[:values])
          current_group = new_group
        end
        current_group.add_record(row[:pk])
      end
      if current_group && (!ignore_empty_groups || current_group.count > 1)
        block.call(current_group)
      end
      result_set.flush!
    end

    def combine_groups
      # Create a new dataset for the groups table
      groups_dataset = result_set.groups_dataset
      groups_dataset.fields.each_value do |field|
        # Sort on all fields
        next if field.primary_key?
        groups_dataset.add_order(field)
        groups_dataset.add_select(field)
      end
      groups_dataset.add_order(groups_dataset.primary_key) # ensure matching groups are sorted by id
      result_set.database do |db|
        groups_to_delete = []
        db.transaction do  # for speed reasons
          group_records_for(groups_dataset, nil, false) do |group|
            if group.count == 1
              # Delete the empty group
              groups_to_delete << group.records[0]
            else
              # Change group_id in the groups_records table to the first group
              # id, delete other groups.
              new_group_id = group.records[0]
              group.records[1..-1].each do |old_group_id|
                # NOTE: There can only be a group with max size of 2, but
                #       this adds in future support for matching more than
                #       2 datasets at once.
                db[:groups_records].filter(:group_id => old_group_id).
                  update(:group_id => new_group_id)
                groups_to_delete << old_group_id
              end
            end
          end
        end
        db[:groups_records].filter(:group_id => groups_to_delete).delete
        db[:groups].filter(:id => groups_to_delete).delete
      end
    end
  end
end
