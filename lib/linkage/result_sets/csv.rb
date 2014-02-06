module Linkage
  module ResultSets
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

        if opts[:dir]
          FileUtils.mkdir_p(opts[:dir])
          dir = opts[:dir]
        else
          dir = '.'
        end

        @scores_file = File.join(dir, opts[:scores_file] || 'scores.csv')
        @matchs_file = File.join(dir, opts[:matches_file] || 'matches.csv')
      end

      def score_set
        @score_set ||= ScoreSet['csv'].new(@scores_file)
      end

      def match_set
        @match_set ||= MatchSet['csv'].new(@matchs_file)
      end
    end

    ResultSet.register('csv', CSV)
  end
end
