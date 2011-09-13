module Linkage
  class SingleThreadedRunner < Runner
    def execute
      create_groups_table
      setup_datasets
      apply_expectations
      group_records
    end

    def setup_datasets
      @dataset_1 = @config.dataset_1.clone
    end

    def apply_expectations
      @config.expectations.each do |exp|
        case exp.kind
        when :self
          @dataset_1.add_select(exp.field_1)
          @dataset_1.add_order(exp.field_1)
        end
      end
    end

    def group_records
      groups = []
      current_group = nil
      @dataset_1.each do |row|
        if current_group.nil? || !current_group.matches?(row[:values])
          if current_group && current_group.count > 1
            groups << current_group
          end
          new_group = Group.new(row[:values])
          current_group = new_group
        end
        current_group.add_record(row[:pk])
      end
      if current_group && current_group.count > 1
        groups << current_group
      end

      database do |db|
        groups.each_with_index do |group, i|
          db[:groups].import(
            [:group_id, :record_id],
            group.records.collect { |record_id| [i+1, record_id] }
          )
        end
      end
    end
  end
end
