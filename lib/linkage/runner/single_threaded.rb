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
    def group_records_for(dataset, dataset_id, ignore_empty_groups = true)
      group_minimum = ignore_empty_groups ? 2 : 1
      dataset.each_group(group_minimum) do |group|
        result_set.add_group(group, dataset_id)
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
      groups_dataset = groups_dataset.match(*exprs)

      groups_dataset.db.transaction do
        # transaction improves speed
        groups_dataset.each_group(1) do |group|
          ds = groups_dataset.filter(group.values)
          if group.count == 1
            ds.delete
          else
            group_ids = ds.select_map(:id)
            groups_dataset.filter(:id => group_ids[1..-1]).delete
          end
        end
      end
    end
  end
end
