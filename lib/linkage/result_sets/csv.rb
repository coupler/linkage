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
    # {CSV#initialize ResultSets::CSV.new} takes either a directory name or a
    # Hash of options.  If you use a directory name, it will set up a
    # {ScoreSets::CSV} and {MatchSets::CSV} to use files within the directory
    # you specified. For example:
    #
    # ```ruby
    # result_set = Linkage::ResultSet['csv'].new("/some/path")
    # ```
    #
    # This will create the following files:
    #
    # * `/some/path/scores.csv`  (for scores)
    # * `/some/path/matches.csv` (for matches)
    #
    # If you use a Hash of options, you can choose each filename individually
    # like so:
    #
    # ```ruby
    # result_set = Linkage::ResultSet['csv'].new({
    #   :scores  => { :filename => "/some/path/foo-scores.csv" },
    #   :matches => { :filename => "/some/other/path/foo-matches.csv" }
    # })
    # ```
    #
    # @see ScoreSets::CSV
    # @see MatchSets::CSV
    class CSV < ResultSet
      def initialize(dir_or_options = nil)
        opts =
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

        @score_set_options = extract_options_for(:scores, opts)
        @match_set_options = extract_options_for(:matches, opts)
      end

      def score_set
        @score_set ||= ScoreSet['csv'].new(@score_set_options)
      end

      def match_set
        @match_set ||= MatchSet['csv'].new(@match_set_options)
      end

      private

      def extract_options_for(name, opts)
        result = {}
        if opts.has_key?(:dir)
          result[:dir] = opts[:dir]
        end
        if opts.has_key?(name)
          result.update(opts[name])
        end
        result
      end
    end

    ResultSet.register('csv', CSV)
  end
end
