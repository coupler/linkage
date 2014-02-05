module Linkage
  module ResultSets
    class CSV < ResultSet
      def initialize(dir_or_options)
        @dir =
          if dir_or_options.is_a?(String)
            dir_or_options
          else
            dir_or_options[:dir]
          end
        FileUtils.mkdir_p(@dir)

        @score_set_file = File.join(@dir, 'scores.csv')
        @match_set_file = File.join(@dir, 'matches.csv')
      end

      def score_set
        @score_set ||= ScoreSet['csv'].new(@score_set_file)
      end

      def match_set
        @match_set ||= MatchSet['csv'].new(@match_set_file)
      end
    end

    ResultSet.register('csv', CSV)
  end
end
