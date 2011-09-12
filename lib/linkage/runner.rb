module Linkage
  # Use this class to run a configuration created by {Dataset#link_with}.
  class Runner
    attr_reader :config

    # @param [Linkage::Configuration] config
    # @param [String] uri Sequel-style database URI
    # @see Dataset#link_with
    # @see http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html Sequel: Connecting to a database
    def initialize(config, uri)
      @config = config
      @uri = uri
    end

    # @abstract
    def execute
      raise NotImplementedError
    end

    protected

    def database
      @database ||= Sequel.connect(@uri)
    end

    def create_groups_table
      schema = config.groups_table_schema
      database.create_table(:groups) do
        schema.each do |col|
          column(col[:name], col[:type], col[:opts] || {})
        end
      end
    end
  end
end

path = Pathname.new(File.expand_path(File.dirname(__FILE__))) + 'runner'
require path + 'single_threaded'
