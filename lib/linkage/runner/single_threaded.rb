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
      @join_expectations = []
      @config.expectations.each do |exp|
        case exp.kind
        when :join
          @join_expectations << exp
          @dataset_1.add_select(exp.field_1)
          @dataset_1.add_order(exp.field_1)
        end
      end
    end

    def group_records
      @dataset_1.each do |row|
      end
    end
  end
end
