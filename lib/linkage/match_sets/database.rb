module Linkage
  module MatchSets
    class Database < MatchSet
      def initialize(options = {})
        @database = options[:conn]
        if @database.nil?
          filename = options[:filename] || "matches.db"
          if options[:dir]
            dir = File.expand_path(options[:dir])
            FileUtils.mkdir_p(dir)
            filename = File.join(dir, filename)
          end
          @database = Sequel.sqlite(filename)
        end
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
