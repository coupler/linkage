module Linkage
  module ResultSets
    # {CSV ResultSets::CSV} is the {ResultSet ResultSet} for writing to CSV
    # files. You can use it by either referencing it directly like so:
    #
    # ```ruby
    # result_set = Linkage::ResultSets::CSV.new(my_options)
    # ```
    #
    # Or by using {ResultSet.[] ResultSet.[]}:
    #
    # ```ruby
    # result_set = Linkage::ResultSet['csv'].new(my_options)
    # ```
    #
    # There is a slight difference between these two ways, however. The latter
    # looks up the {ResultSet} class that is registered under the name `'csv'`.
    # By default, the registered class is {CSV Linkage::ResultSets::CSV}, but if
    # that gets overridden (by a plugin, for example), the result of
    # `Linkage::ResultSet['csv']` will be whatever was registered.
    #
    # {CSV#initialize ResultSets::CSV.new} takes either a directory name as its
    # argument or a Hash of options. Passing in a directory name is equivalent to
    # passing in a Hash with the `:dir` key. For example:
    #
    # ```ruby
    # result_set = Linkage::ResultSet['csv'].new("/some/path")
    # ```
    #
    # is the same as:
    #
    # ```ruby
    # result_set = Linkage::ResultSet['csv'].new({:dir => "/some/path"})
    # ```
    #
    # Any options you pass to {CSV#initialize} will be passed directly to
    # {ScoreSets::CSV#initialize} and {MatchSets::CSV#initialize}. In the above
    # example, the following files will be created:
    #
    # * `/some/path/scores.csv`  (for scores)
    # * `/some/path/matches.csv` (for matches)
    #
    # @see ScoreSets::CSV
    # @see MatchSets::CSV
    class CSV < ResultSet
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
