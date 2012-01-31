module Linkage
  module Dataset
    module Plugin
      module ClassMethods
        # @return [Linkage::FieldSet]
        attr_reader :field_set

        # Setup a linkage with another dataset
        #
        # @return [Linkage::Configuration]
        def link_with(dataset, &block)
          conf = Configuration.new(self, dataset)
          conf.configure(&block)
          conf
        end

        def clone
          Linkage::Dataset.at(db.uri, table_name, db.opts)
        end
      end

      def self.apply(model)
        model.instance_variable_set(:@field_set, FieldSet.new(model.db_schema, model))
      end
    end

    # @param [String] uri Sequel-style database URI
    # @param [String, Symbol] table Database table name
    # @param [Hash] options Options to pass to Sequel.connect
    # @see http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html Sequel: Connecting to a database
    def self.at(uri, table, options = {})
      db = Sequel.connect(uri, options)
      klass = Class.new(Sequel::Model(db[table.to_sym]))
      klass.plugin(Linkage::Dataset::Plugin)
      klass
    end

    class << self; alias_method(:new, :at); end
  end
end
