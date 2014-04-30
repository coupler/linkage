module Linkage
  # {Configuration} keeps track of everything needed to run a record linkage,
  # including which datasets you want to link, how you want to link them, and
  # where you want to store the results. Once created, you can supply the
  # {Configuration} to {Runner#initialize} and run it with {Runner#execute}.
  #
  # To create a configuration, usually you will want to use {Dataset#link_with},
  # but you can create it directly if you like (see {#initialize}), like so:
  #
  # ```ruby
  # dataset_1 = Linkage::Dataset.new('mysql://example.com/database_name', 'foo')
  # dataset_2 = Linkage::Dataset.new('postgres://example.com/other_name', 'bar')
  # result_set = Linkage::ResultSet['csv'].new('/home/foo/linkage')
  # config = Linkage::Configuration.new(dataset_1, dataset_2, result_set)
  # ```
  #
  # To add comparators to {Configuration}, you can call methods with the same
  # name as registered comparators. Here's the list of builtin comparators:
  #
  # | Name       | Class                     |
  # |------------|---------------------------|
  # | compare    | {Comparators::Compare}    |
  # | strcompare | {Comparators::Strcompare} |
  # | within     | {Comparators::Within}     |
  #
  # For example, if you want to add a {Comparators::Compare} comparator to
  # your configuration, run this:
  #
  # ```ruby
  # config.compare([:foo], [:bar], :equal_to)
  # ```
  #
  # This works via {Configuration#method_missing}. First, the comparator class
  # is fetched via {Comparator.[]}. Then fields are looked up in the {FieldSet}
  # of the {Dataset}. Those {Field}s along with any other arguments you specify
  # are passed to the constructor of the comparator you chose.
  #
  # {Configuration} also contains information about how records are matched.
  # Once scores are computed, the scores for each pair of records are averaged
  # and compared against a threshold value. Record pairs that have an average
  # score greater than or equal to the threshold value are considered matches.
  #
  # The threshold value is `0.5` by default, but you can change it by setting
  # {#threshold} like so:
  #
  # ```ruby
  # config.threshold = 0.75
  # ```
  #
  # Since scores range between 0 and 1 (inclusive), be sure to set a threshold
  # value within the same range. The actual matching work is done by the
  # {Matcher} class.
  #
  # @see Dataset
  # @see ResultSet
  # @see Comparator
  # @see Matcher
  # @see Runner
  class Configuration
    attr_reader :dataset_1, :dataset_2, :result_set, :comparators, :threshold
    attr_accessor :algorithm

    def threshold=(threshold)
      if not threshold.is_a?(Numeric)
        raise "threshold must be numeric type"
      end
      @threshold = threshold
    end
    # Create a new instance of {Configuration}.
    #
    # @overload initialize(dataset_1, dataset_2, result_set)
    #   Create a linkage configuration for two datasets.
    #   @param [Linkage::Dataset] dataset_1
    #   @param [Linkage::Dataset] dataset_2
    #   @param [Linkage::ResultSet] result_set
    # @overload initialize(dataset, result_set)
    #   Create a linkage configuration for one dataset.
    #   @param [Linkage::Dataset] dataset
    #   @param [Linkage::ResultSet] result_set
    # @overload initialize(dataset_1, dataset_2, score_set, match_set)
    #   Create a linkage configuration for two datasets.
    #   @param [Linkage::Dataset] dataset_1
    #   @param [Linkage::Dataset] dataset_2
    #   @param [Linkage::ScoreSet] score_set
    #   @param [Linkage::MatchSet] match_set
    # @overload initialize(dataset, score_set, match_set)
    #   Create a linkage configuration for one dataset.
    #   @param [Linkage::Dataset] dataset
    #   @param [Linkage::ScoreSet] score_set
    #   @param [Linkage::MatchSet] match_set
    def initialize(*args)
      if args.length < 2 || args.length > 4
        raise ArgumentError, "wrong number of arguments (#{args.length} for 2..4)"
      end

      @dataset_1 = args[0]
      case args.length
      when 2
        # dataset and result set
        @result_set = args[1]
      when 3
        # dataset 1, dataset 2, and result set
        # dataset, score set, and match set
        case args[1]
        when Dataset, nil
          @dataset_2 = args[1]
          @result_set = args[2]
        when ScoreSet
          @result_set = ResultSet.new(args[1], args[2])
        end
      when 4
        # dataset 1, dataset 2, score set, and match set
        @dataset_2 = args[1]
        @result_set = ResultSet.new(args[2], args[3])
      end

      @comparators = []
      @algorithm = :mean
      @threshold = 0.5
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
      Matcher.new(@comparators, @result_set.score_set, @algorithm, @threshold)
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
      return comparator
    end

    protected

    def fields_for(dataset, *args)
      field_set = dataset.field_set
      args.collect { |name| field_set[name] }
    end
  end
end
