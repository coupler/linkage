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
        end

        @score_set_args = extract_args_for(:scores, opts)
        @match_set_args = extract_args_for(:matches, opts)
      end

      def score_set
        @score_set ||= ScoreSet['csv'].new(*@score_set_args)
      end

      def match_set
        @match_set ||= MatchSet['csv'].new(*@match_set_args)
      end

      private

      def extract_args_for(name, opts)
        dir = opts[:dir] || '.'
        opts = opts[name]

        filename =
          case opts
          when Hash, nil
            opts = opts ? opts.dup : {}
            opts.delete(:filename) || "#{name}.csv"
          when String
            opts
          end
        [File.join(dir, filename), opts]
      end
    end

    ResultSet.register('csv', CSV)
  end
end
