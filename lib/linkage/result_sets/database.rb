module Linkage
  module ResultSets
    # {Database ResultSets::Database} is the {ResultSet ResultSet} for writing
    # to database tables. You can use it by either referencing it directly like
    # so:
    #
    # ```ruby
    # result_set = Linkage::ResultSets::Database.new(my_options)
    # ```
    #
    # Or by using {ResultSet.[] ResultSet.[]}:
    #
    # ```ruby
    # result_set = Linkage::ResultSet['database'].new(my_options)
    # ```
    #
    # There is a slight difference between these two ways, however. The latter
    # looks up the {ResultSet} class that is registered under the name
    # `'database'`.  By default, the registered class is {Database
    # Linkage::ResultSets::Database}, but if that gets overridden (by a plugin,
    # for example), the result of `Linkage::ResultSet['database']` will be
    # whatever was registered.
    #
    # {Database#initialize ResultSets::Database.new} takes either a
    # {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Database.html Sequel::Database},
    # a String, or a Hash of options. If you pass in a
    # {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Database.html Sequel::Database},
    # {Database ResultSets::Database} passes that database to both
    # {ScoreSets::Database} and {MatchSets::Database}:
    #
    # ```ruby
    # db = Sequel.connect("mysql2://example.com")
    # result_set = Linkage::ResultSet['database'].new(db)
    # ```
    #
    # In this case, default options are used in the score set and match set.
    #
    # If you pass in a String,
    # {http://sequel.jeremyevans.net/rdoc/classes/Sequel.html#method-c-connect Sequel.connect}
    # will be called with the string:
    #
    # ```ruby
    # result_set = Linkage::ResultSet['database'].new("mysql2://example.com")
    # ```
    #
    # In this case, default options are also used in the score set and match
    # set.
    #
    # If you pass in a Hash of options, all values in the Hash except `:scores`
    # and `:matches` will be passed to
    # {http://sequel.jeremyevans.net/rdoc/classes/Sequel.html#method-c-connect Sequel.connect}.
    # The value of `:scores` will be passed to
    # {ScoreSets::Database#initialize}, and the value of `:matches` will be
    # passed to {MatchSets::Database#initialize}.
    #
    # ```ruby
    # result_set = Linkage::ResultSet['database'].new({
    #   :adapter => 'mysql2',
    #   :username => 'foo',
    #   :password => 'secret',
    #   :scores  => { :table_name => 'foo_scores'  },
    #   :matches => { :table_name => 'foo_matches' },
    # })
    # ```
    #
    # @see ScoreSets::Database
    # @see MatchSets::Database
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
