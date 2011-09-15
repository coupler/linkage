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
          foreign_key :group_id, :groups
          Integer :dataset
        end
      end
    end
  end
end

path = Pathname.new(File.expand_path(File.dirname(__FILE__))) + 'runner'
require path + 'single_threaded'
