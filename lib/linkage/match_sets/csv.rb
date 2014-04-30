require 'csv'

module Linkage
  module MatchSets
    # {CSV MatchSets::CSV} is an implementation of {MatchSet} for saving
    # matches in a CSV file.
    #
    # There are three options available:
    #
    #  * `:filename` - which file to store matches in; can be an absolute path
    #     or relative path
    #  * `:dir` - which directory to put the file in; used if `:filename` is a
    #     relative path
    #  * `:overwrite` - indicate whether or not to overwrite an existing file
    #
    # By default, `:filename` is `'matches.csv'`, and the other options are
    # blank. This means that it will write matches to the `'matches.csv'` file
    # in the current working directory and will raise an error if the file
    # already exists.
    #
    # If you specify `:dir`, that path will be created if it doesn't exist yet.
    #
    # The resulting file looks like this:
    #
    #     id_1,id_2,score
    #     123,456,0.75
    #     124,457,1
    #
    # @see Helpers::CSV
    class CSV < MatchSet
      include Helpers::CSV

      DEFAULT_OPTIONS = {
        :filename => 'matches.csv'
      }

      def initialize(options = {})
        @options = DEFAULT_OPTIONS.merge(options.reject { |k, v| v.nil? })
      end

      def open_for_writing
        return if @mode == :write

        @csv = open_csv_for_writing(@options)
        @csv << %w{id_1 id_2 score}
        @mode = :write
      end

      def add_match(id_1, id_2, score)
        raise "not in write mode" if @mode != :write
        if score.equal?(1.0) || score.equal?(0.0)
          score = score.floor
        end
        @csv << [id_1, id_2, score]
      end

      def close
        @mode = nil
        @csv.close if @csv
      end
    end

    MatchSet.register('csv', CSV)
  end
end
