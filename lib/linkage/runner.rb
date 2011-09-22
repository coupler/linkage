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
      @next_group_id = 1
      @next_group_mutex = Mutex.new
    end

    # @abstract
    def execute
      raise NotImplementedError
    end

    protected

    def database(&block)
      Sequel.connect(@uri, &block)
    end

    def create_tables
      database do |db|
        schema = config.groups_table_schema
        db.create_table(:groups) do
          schema.each { |col| column(*col) }
        end

        pk_type = config.dataset_1.primary_key.merge(config.dataset_2.primary_key).ruby_type
        db.create_table(:groups_records) do
          column(:record_id, pk_type[:type], pk_type[:opts] || {})
          Integer :group_id
          Integer :dataset
        end
      end
    end

    def next_group_id
      result = nil
      @next_group_mutex.synchronize do
        result = @next_group_id
        @next_group_id += 1
      end
      result
    end
  end
end

path = Pathname.new(File.expand_path(File.dirname(__FILE__))) + 'runner'
require path + 'single_threaded'
