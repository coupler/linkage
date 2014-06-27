module Linkage
  module MatchSets
    # {Database MatchSets::Database} is an implementation of {MatchSet} for saving
    # matches in a relational database.
    #
    # Matches are saved in a database table with the following columns:
    # - id_1 (string)
    # - id_2 (string)
    # - score (float)
    #
    # You can setup a database connection in a few different ways. By default, a
    # SQLite database with the filename of `matches.db` will be created in the
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
    # set. By default, the table name used is called `matches`, but you change
    # that by setting the `:table_name` option in the second options hash. If
    # the table already exists, an {ExistsError} will be raised unless you set
    # the `:overwrite` option to a truthy value in the second options hash.
    #
    # @see Helpers::Database
    class Database < MatchSet
      include Helpers::Database

      DEFAULT_OPTIONS = {
        :filename => 'matches.db'
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
        @table_name = options[:table_name] || :matches
        @overwrite = options[:overwrite]
      end

      def open_for_writing
        return if @mode == :write

        if @overwrite
          @database.drop_table?(@table_name)
        elsif @database.table_exists?(@table_name)
          raise ExistsError, "#{@table_name} table exists and not in overwrite mode"
        end

        @database.create_table(@table_name) do
          String :id_1
          String :id_2
          Float :score
        end
        @dataset = @database[@table_name]
        @mode = :write
      end

      def add_match(id_1, id_2, score)
        raise "not in write mode" if @mode != :write

        @dataset.insert({
          :id_1 => id_1,
          :id_2 => id_2,
          :score => score
        })
      end

      def close
        @mode = nil
      end
    end

    MatchSet.register('database', Database)
  end
end
