module Linkage
  module MatchSets
    class Database < MatchSet
      include Helpers::Database

      DEFAULT_OPTIONS = {
        :filename => 'matches.db'
      }

      # @override initialize(options = {})
      #   @param [Hash] options
      # @override initialize(uri, options = {})
      #   @param [String] uri
      #   @param [Hash] options
      def initialize(*args)
        connection_options = args.shift
        @database = database_connection(connection_options, DEFAULT_OPTIONS)

        options =
          if connection_options.is_a?(String)
            args.shift
          else
            connection_options
          end
        options ||= {}

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
