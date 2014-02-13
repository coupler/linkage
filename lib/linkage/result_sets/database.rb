module Linkage
  module ResultSets
    class Database < ResultSet
      def initialize(database_or_options = nil)
        @database = nil
        @options = {}

        if database_or_options.kind_of?(Sequel::Database)
          @database = database_or_options
        else
          database_opts = nil
          case database_or_options
          when String
            database_opts = database_or_options
          when Hash
            database_opts = {}
            database_or_options.each_pair do |key, value|
              if key == :scores || key == :matches
                @options[key] = value
              else
                database_opts[key] = value
              end
            end
          else
            raise ArgumentError, "expected Sequel::Database, a String, or a Hash, got #{database_or_options.class}"
          end
          @database = Sequel.connect(database_opts)
        end
      end

      def score_set
        @score_set ||= ScoreSet['database'].new(@database, @options[:scores] || {})
      end

      def match_set
        @match_set ||= MatchSet['database'].new(@database, @options[:matches] || {})
      end
    end

    ResultSet.register('database', Database)
  end
end
