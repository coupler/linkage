module Linkage
  # A runner class that only uses a single thread to execute a linkage.
  #
  # @see Runner
  class SingleThreadedRunner < Runner
    # @return [Linkage::ResultSet]
    def execute
      result_set.create_tables!

      if !config.simple_expectations.empty?
        setup_datasets
        group_records
        score_records_with_groups
      else
        dataset_1, dataset_2 = config.datasets_with_applied_exhaustive_expectations
        score_records_without_groups(dataset_1, dataset_2)
      end

      result_set.flush!
      return result_set
    end

    private

    def setup_datasets
      @dataset_1, @dataset_2 = config.datasets_with_applied_simple_expectations

      pk = @dataset_1.field_set.primary_key
      @dataset_1 = @dataset_1.select(pk.to_expr)
      if @config.linkage_type != :self
        pk = @dataset_2.field_set.primary_key
        @dataset_2 = @dataset_2.select(pk.to_expr)
      end
    end

    def group_records
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

      groups_dataset.field_set.values.each do |field|
        # Sort on all fields
        if !field.primary_key?
          meta_object = MetaObject.new(field)
          groups_dataset = groups_dataset.group_match_more(meta_object)
        end
      end

      # Delete non-matching groups
      sub_dataset = groups_dataset.select(:id).group_by_matches.having(:count.sql_function(:id) => 1)
      groups_dataset.filter(:id => sub_dataset.obj).delete

      # Delete duplicate groups
      sub_dataset = groups_dataset.select(:max.sql_function(:id).as(:id)).group_by_matches
      groups_dataset.filter(:id => sub_dataset.obj).delete
    end

    def score_records_with_groups
      result_set.groups_dataset.each do |group_record|
        group = Group.from_row(group_record)
        dataset_1, dataset_2 = result_set.groups_records_datasets(group)
        score_records_without_groups(dataset_1, dataset_2)
      end
    end

    def score_records_without_groups(dataset_1, dataset_2)
      pk_1 = dataset_1.field_set.primary_key.to_expr
      pk_2 = dataset_2.field_set.primary_key.to_expr

      config.exhaustive_expectations.each_with_index do |expectation, comparator_id|
        comparator = expectation.comparator

        dataset_1.each do |record_1|
          dataset_2.each do |record_2|
            score = comparator.score(record_1, record_2)
            result_set.add_score(comparator_id, record_1[pk_1], record_2[pk_2],
              score)
          end
        end
      end
    end
  end
end
