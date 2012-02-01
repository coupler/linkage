module Linkage
  # A runner class that only uses a single thread to execute a linkage.
  #
  # @see Runner
  class SingleThreadedRunner < Runner
    # @return [Linkage::ResultSet]
    def execute
      setup_datasets
      apply_expectations
      group_records

      return result_set
    end

    private

    def setup_datasets
      pk = config.dataset_1.field_set.primary_key
      @dataset_1 = config.dataset_1.select(pk.to_expr)
      if @config.linkage_type != :self
        pk = config.dataset_2.field_set.primary_key
        @dataset_2 = config.dataset_2.select(pk.to_expr)
      end
    end

    def apply_expectations
      config.expectations.each do |exp|
        @dataset_1 = exp.apply_to(@dataset_1, :lhs)
        @dataset_2 = exp.apply_to(@dataset_2, :rhs) if config.linkage_type != :self
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
      primary_key = dataset.field_set.primary_key.to_expr
      dataset.each do |row|
        pk = row.delete(primary_key)
        if current_group.nil? || !current_group.matches?(row)
          if current_group && (!ignore_empty_groups || current_group.count > 1)
            block.call(current_group)
          end
          new_group = Group.new(row)
          current_group = new_group
        end
        current_group.add_record(pk)
      end
      if current_group && (!ignore_empty_groups || current_group.count > 1)
        block.call(current_group)
      end
      result_set.flush!
    end

    def combine_groups
      # Create a new dataset for the groups table
      groups_dataset = result_set.groups_dataset

      exprs = groups_dataset.field_set.values.inject([]) do |arr, field|
        # Sort on all fields
        field.primary_key? ? arr : arr << field.to_expr
      end
      groups_dataset = groups_dataset.select(*exprs, groups_dataset.field_set.primary_key.to_expr).order(*exprs) # ensure matching groups are sorted by id

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
