module Linkage
  module ScoreSets
    # {Database ScoreSets::Database} is an implementation of {ScoreSet} for saving
    # scores in a relational database.
    #
    # Scores are saved in a database table with the following columns:
    # - comparator_id (integer)
    # - id_1 (string)
    # - id_2 (string)
    # - score (float)
    #
    # You can setup a database connection in a few different ways. By default, a
    # SQLite database with the filename of `scores.db` will be created in the
    # current working directory. If you want something different, you can either
    # specify a Sequel-style URI, provide connection options for
    # `Sequel.connect`, or you can just specify a `Sequel::Database` object to
    # use.
    #
    # There are a couple of non-Sequel connection options:
    #  * `:filename` - specify filename to use for a SQLite database
    #  * `:dir` - specify the parent directory for a SQLite database
    #
    # In addition to connection options, there are behavioral options you can
    # set. By default, the table name used is called `scores`, but you change
    # that by setting the `:table_name` option in the second options hash. If
    # the table already exists, an {ExistsError} will be raised unless you set
    # the `:overwrite` option to a truthy value in the second options hash.
    class Database < ScoreSet
      include Helpers::Database

      DEFAULT_OPTIONS = {
        :filename => 'scores.db'
      }

      # @override initialize(connection_options = {}, options = {})
      #   @param connection_options [Hash]
      #   @param options [Hash]
      # @override initialize(uri, options = {})
      #   @param uri [String]
      #   @param options [Hash]
      # @override initialize(database, options = {})
      #   @param database [Sequel::Database]
      #   @param options [Hash]
      def initialize(connection_options = {}, options = {})
        @database = database_connection(connection_options, DEFAULT_OPTIONS)
        @table_name = options[:table_name] || :scores
        @overwrite = options[:overwrite]
      end

      def open_for_reading
        raise "already open for writing, try closing first" if @mode == :write
        return if @mode == :read

        if !@database.table_exists?(@table_name)
          raise MissingError, "#{@table_name} table does not exist"
        end

        @dataset = @database[@table_name]
        @mode = :read
      end

      def open_for_writing
        raise "already open for reading, try closing first" if @mode == :read
        return if @mode == :write

        if @overwrite
          @database.drop_table?(@table_name)
        elsif @database.table_exists?(@table_name)
          raise ExistsError, "#{@table_name} table exists and not in overwrite mode"
        end

        @database.create_table(@table_name) do
          Integer :comparator_id
          String :id_1
          String :id_2
          Float :score
        end
        @dataset = @database[@table_name]
        @mode = :write
      end

      def add_score(comparator_id, id_1, id_2, score)
        raise "not in write mode" if @mode != :write

        @dataset.insert({
          :comparator_id => comparator_id,
          :id_1 => id_1,
          :id_2 => id_2,
          :score => score
        })
      end

      def each_pair
        raise "not in read mode" if @mode != :read

        current_pair = nil
        @dataset.order(:id_1, :id_2, :comparator_id).each do |row|
          if current_pair.nil? || current_pair[0] != row[:id_1] || current_pair[1] != row[:id_2]
            yield(*current_pair) unless current_pair.nil?
            current_pair = [row[:id_1], row[:id_2], {}]
          end
          scores = current_pair[2]
          scores[row[:comparator_id]] = row[:score]
        end
        yield(*current_pair) unless current_pair.nil?
      end

      def close
        @mode = nil
      end
    end

    ScoreSet.register('database', Database)
  end
end
