module Linkage
  class Configuration
    attr_reader :dataset_1, :dataset_2, :result_set, :comparators
    attr_accessor :record_cache_size, :algorithm, :threshold

    def initialize(*args)
      if args.length < 2 || args.length > 3
        raise ArgumentError, "wrong number of arguments (#{args.length} for 3..4)"
      end

      @dataset_1 = args[0]
      if args.length > 2 && args[1]
        @dataset_2 = args[1]
      end
      @result_set = args[-1]

      @comparators = []
      @record_cache_size = 10_000
    end

    def score_recorder
      pk_1 = @dataset_1.field_set.primary_key.name
      if @dataset_2
        pk_2 = @dataset_2.field_set.primary_key.name
      else
        pk_2 = pk_1
      end
      ScoreRecorder.new(@comparators, @result_set.score_set, [pk_1, pk_2])
    end

    def matcher
      Matcher.new(@comparators, @result_set.score_set, @algorithm || :mean, @threshold || 0.5)
    end

    def match_recorder(matcher)
      MatchRecorder.new(matcher, @result_set.match_set)
    end

    def method_missing(name, *args, &block)
      klass = Comparator[name.to_s]
      if klass.nil?
        raise "unknown comparator: #{name}"
      end

      set_1 = args[0]
      if set_1.is_a?(Array)
        set_1 = fields_for(dataset_1, *set_1)
      else
        set_1 = fields_for(dataset_1, set_1).first
      end
      args[0] = set_1

      set_2 = args[1]
      if set_2.is_a?(Array)
        set_2 = fields_for(dataset_2 || dataset_1, *set_2)
      else
        set_2 = fields_for(dataset_2 || dataset_1, set_2).first
      end
      args[1] = set_2

      comparator = klass.new(*args, &block)
      @comparators << comparator
    end

    protected

    def fields_for(dataset, *args)
      field_set = dataset.field_set
      args.collect { |name| field_set[name] }
    end
  end
end
