module Linkage
  # Use this class to run a configuration created by {Dataset#link_with}.
  class Runner
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
  end
end

path = Pathname.new(File.expand_path(File.dirname(__FILE__))) + 'runner'
require path + 'single_threaded'
