module Linkage
  # Use this class to run a configuration created by {Dataset#link_with}.
  class Runner
    attr_reader :config

    # @param [Linkage::Configuration] config
    # @see Dataset#link_with
    def initialize(config)
      @config = config
    end

    def execute
      score_records
      match_records
    end

    def score_records
      score_recorder = config.score_recorder
      score_recorder.start
      dataset_1 = config.dataset_1
      dataset_2 = config.dataset_2
      simple_comparators = []
      config.comparators.each do |comparator|
        if comparator.type == :simple
          simple_comparators << comparator
        else
          if dataset_2
            comparator.score_datasets(dataset_1, dataset_2)
          else
            comparator.score_dataset(dataset_1)
          end
        end
      end

      # Handle simple comparators
      unless simple_comparators.empty?
        if dataset_2
          # Two datasets
          dataset_1.each do |record_1|
            dataset_2.each do |record_2|
              simple_comparators.each do |comparator|
                comparator.score_and_notify(record_1, record_2)
              end
            end
          end
        else
          # One dataset
          # NOTE: very naive implementation
          records = dataset_1.all
          0.upto(records.length - 2) do |i|
            record_1 = records[i]
            (i + 1).upto(records.length - 1) do |j|
              record_2 = records[j]
              simple_comparators.each do |comparator|
                comparator.score_and_notify(record_1, record_2)
              end
            end
          end
        end
      end
      score_recorder.stop
    end

    def match_records
      matcher = config.matcher
      match_recorder = config.match_recorder(matcher)
      match_recorder.start
      matcher.run
      match_recorder.stop
    end
  end
end
