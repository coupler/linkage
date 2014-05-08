module Linkage
  module ResultSets
    # {CSV ResultSets::CSV} is a subclass of {ResultSet ResultSet} that makes it
    # convenient to set up a {ScoreSets::CSV} and {MatchSets::CSV} at the same
    # time. For example:
    #
    # ```ruby
    # result_set = Linkage::ResultSets::CSV.new('/some/path')
    # ```
    #
    # Or by using {ResultSet.[] ResultSet.[]}:
    #
    # ```ruby
    # result_set = Linkage::ResultSet['csv'].new('/some/path')
    # ```
    #
    # {#initialize ResultSets::CSV.new} takes either a directory name as its
    # argument or a Hash of options. Passing in a directory name is equivalent
    # to passing in a Hash with the `:dir` key. For example:
    #
    # ```ruby
    # result_set = Linkage::ResultSet['csv'].new('/some/path')
    # ```
    #
    # is the same as:
    #
    # ```ruby
    # result_set = Linkage::ResultSet['csv'].new({:dir => '/some/path'})
    # ```
    #
    # The `:dir` option lets you specify the parent directory for the score set
    # and result set files (which are `scores.csv` and `results.csv` by default).
    #
    # The only other relevant option is `:overwrite`, which controls whether or
    # not overwriting existing files is permitted.
    #
    # @see ScoreSets::CSV
    # @see MatchSets::CSV
    class CSV < ResultSet
      # @overload initialize(dir)
      #   @param [String] dir parent directory of CSV files
      # @overload initialize(options)
      #   @param [Hash] options
      #   @option options [String] :dir parent directory of CSV files
      #   @option options [Boolean] :overwrite (false) whether or not to allow
      #     overwriting existing files
      def initialize(dir_or_options = nil)
        @options =
          case dir_or_options
          when nil
            {}
          when String
            {:dir => dir_or_options}
          when Hash
            dir_or_options
          else
            raise ArgumentError, "expected nil, a String, or a Hash, got #{dir_or_options.class}"
          end
      end

      def score_set
        @score_set ||= ScoreSet['csv'].new(@options)
      end

      def match_set
        @match_set ||= MatchSet['csv'].new(@options)
      end
    end

    ResultSet.register('csv', CSV)
  end
end
