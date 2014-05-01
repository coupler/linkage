require 'csv'

module Linkage
  module ScoreSets
    # {CSV ScoreSets::CSV} is an implementation of {ScoreSet} for saving scores
    # in a CSV file.
    #
    # There are three options available:
    #
    #  * `:filename` - which file to store scores in; can be an absolute path
    #     or relative path
    #  * `:dir` - which directory to put the file in; used if `:filename` is a
    #     relative path
    #  * `:overwrite` - indicate whether or not to overwrite an existing file
    #
    # By default, `:filename` is `'scores.csv'`, and the other options are
    # blank. This means that it will write scores to the `'scores.csv'` file in
    # the current working directory and will raise an error if the file already
    # exists.
    #
    # If you specify `:dir`, that path will be created if it doesn't exist yet.
    #
    # The resulting file looks like this:
    #
    #     comparator_id,id_1,id_2,score
    #     1,123,456,1
    #     1,124,457,0.5
    #     2,123,456,0
    #
    # @see Helpers::CSV
    class CSV < ScoreSet
      include Linkage::Helpers::CSV

      DEFAULT_OPTIONS = {
        :filename => 'scores.csv'
      }

      # @param [Hash] options
      # @option options [String] :filename
      # @option options [String] :dir
      # @option options [Boolean] :overwrite
      def initialize(options = {})
        @options = DEFAULT_OPTIONS.merge(options.reject { |k, v| v.nil? })
      end

      def open_for_reading
        raise "already open for writing, try closing first" if @mode == :write
        return if @mode == :read

        @csv = open_csv_for_reading(@options)
        @mode = :read
      end

      def open_for_writing
        raise "already open for reading, try closing first" if @mode == :read
        return if @mode == :write

        @csv = open_csv_for_writing(@options)
        @csv << %w{comparator_id id_1 id_2 score}
        @mode = :write
      end

      def add_score(comparator_id, id_1, id_2, score)
        raise "not in write mode" if @mode != :write
        @csv << [comparator_id, id_1, id_2, score]
      end

      def each_pair
        raise "not in read mode" if @mode != :read

        pairs = Hash.new { |h, k| h[k] = {} }
        @csv.each do |row|
          key = [row['id_1'], row['id_2']]
          score = row['score']
          pairs[key][row['comparator_id'].to_i] = score.to_f
        end
        pairs.each_pair do |pair, scores|
          yield pair[0], pair[1], scores
        end
      end

      def close
        @mode = nil
        @csv.close if @csv
      end
    end

    ScoreSet.register('csv', CSV)
  end
end
