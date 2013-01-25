module Linkage
  # A runner class that only uses a single thread to execute a linkage.
  #
  # @see Runner
  class SingleThreadedRunner < Runner
    # @return [Linkage::ResultSet]
    def execute
      result_set.create_tables!

      @pk_1 = config.dataset_1.field_set.primary_key.to_expr
      @pk_2 = config.dataset_2.field_set.primary_key.to_expr
      if config.has_simple_expectations?
        setup_datasets
        group_records

        if config.has_exhaustive_expectations?
          score_records_with_groups
        else
          create_matches
        end
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

      @dataset_1 = @dataset_1.select(@pk_1)
      if @config.linkage_type != :self
        @dataset_2 = @dataset_2.select(@pk_2)
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
        dataset_1, dataset_2 = config.apply_exhaustive_expectations(
          *result_set.groups_records_datasets(group))
        score_records_without_groups(dataset_1, dataset_2)
      end
    end

    def score_records_without_groups(dataset_1, dataset_2)
      if config.linkage_type == :self
        keys = dataset_1.select_map(@pk_1)
        unfiltered_dataset = dataset_1.unfiltered
        cache = Hashery::LRUHash.new(config.record_cache_size) do |h, k|
          h[k] = unfiltered_dataset.filter(@pk_1 => k).first
        end
        upper_bound = keys.length - 1

        forward = true
        keys.each_with_index do |key_1, key_1_index|
          record_1 = cache[key_1]

          lower_bound = key_1_index + 1
          enum =
            if forward
              lower_bound.upto(upper_bound)
            else
              upper_bound.downto(lower_bound)
            end
          enum.each do |key_2_index|
            record_2 = cache[keys[key_2_index]]
            score(record_1, record_2)
          end
          forward = !forward
        end
      else
        keys_2 = dataset_2.select_map(@pk_2)
        unfiltered_dataset_2 = dataset_2.unfiltered
        cache_2 = Hashery::LRUHash.new(config.record_cache_size) do |h, k|
          h[k] = unfiltered_dataset_2.filter(@pk_2 => k).first
        end
        keys_2_last = keys_2.length - 1

        forward = true
        dataset_1.each do |record_1|
          enum = forward ? 0.upto(keys_2_last) : keys_2_last.downto(0)
          enum.each do |key_2_index|
            record_2 = cache_2[keys_2[key_2_index]]
            score(record_1, record_2)
          end
          forward = !forward
        end
      end
    end

    def score(record_1, record_2)
      pk_1 = record_1[@pk_1]
      pk_2 = record_2[@pk_2]

      catch(:stop) do
        total_score = 0
        config.exhaustive_expectations.each_with_index do |expectation, comparator_id|
          comparator = expectation.comparator

          score = comparator.score(record_1, record_2)
          result_set.add_score(comparator_id, pk_1, pk_2, score)

          throw(:stop) unless expectation.satisfied?(score)
          total_score += score
        end
        result_set.add_match(pk_1, pk_2, total_score)
      end
    end

    # Only needed for linkages without exhaustive expectations
    def create_matches
      result_set.groups_dataset.each do |group_record|
        group = Group.from_row(group_record)
        dataset_1, dataset_2 = result_set.groups_records_datasets(group)

        if config.linkage_type == :self
          keys = dataset_1.select_map(@pk_1)
          keys_last = keys.length - 1
          keys.each_with_index do |key_1, key_1_index|
            (key_1_index + 1).upto(keys_last) do |key_2_index|
              key_2 = keys[key_2_index]
              result_set.add_match(key_1, key_2, nil)
            end
          end
        else
          keys_1 = dataset_1.select_map(@pk_1)
          keys_2 = dataset_2.select_map(@pk_2)

          keys_1.each do |key_1|
            keys_2.each do |key_2|
              result_set.add_match(key_1, key_2, nil)
            end
          end
        end
      end
    end
  end
end
