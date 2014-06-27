module Linkage
  module ResultSets
    # {Database ResultSets::Database} is the {ResultSet ResultSet} for writing
    # to database tables. You can use it by either referencing it directly like
    # so:
    #
    # ```ruby
    # result_set = Linkage::ResultSets::Database.new(connection_options, options)
    # ```
    #
    # Or by using {ResultSet.[] ResultSet.[]}:
    #
    # ```ruby
    # result_set = Linkage::ResultSet['database'].new(connection_options, options)
    # ```
    #
    # You can setup a database connection in a few different ways. By default, a
    # SQLite database with the filename of `results.db` will be created in the
    # current working directory. If you want something different, you can either
    # specify a Sequel-style URI, provide connection options for
    # `Sequel.connect`, or you can just specify a
    # {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Database.html Sequel::Database}
    # object to use.
    #
    # There are a couple of non-Sequel connection options:
    #  * `:filename` - specify filename to use for a SQLite database
    #  * `:dir` - specify the parent directory for a SQLite database
    #
    # This result set creates a {ScoreSets::Database database-backed score set}
    # and a {Matchsets::Database database-backed match set} with their default
    # table names (`scores` and `matches` respectively.  If either table already
    # exists, an {ExistsError} will be raised unless you set the `:overwrite`
    # option to a truthy value in the second options hash.
    #
    # @see ScoreSets::Database
    # @see MatchSets::Database
    class Database < ResultSet
      include Helpers::Database

      DEFAULT_OPTIONS = {
        :filename => 'results.db'
      }

      def initialize(connection_options = {}, options = {})
        @database = database_connection(connection_options, DEFAULT_OPTIONS)
        @options = options
      end

      def score_set
        @score_set ||= ScoreSet['database'].new(@database, @options)
      end

      def match_set
        @match_set ||= MatchSet['database'].new(@database, @options)
      end
    end

    ResultSet.register('database', Database)
  end
end
