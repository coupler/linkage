module Linkage
  # Use this class to run a configuration created by {Dataset#link_with}.
  class Runner
    attr_reader :config, :result_set

    # @param [Linkage::Configuration] config
    # @param [String] uri Sequel-style database URI
    # @param [Hash] options Sequel.connect options
    # @see Dataset#link_with
    # @see http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html Sequel: Connecting to a database
    def initialize(config, uri = nil, options = {})
      @config = config
      if uri
        warn("[DEPRECATION] Please use Configuration#save_results_in with the database URI and options instead")
        @config.save_results_in(uri, options)
      end
    end

    # @abstract
    def execute
      raise NotImplementedError
    end

    def result_set
      @config.result_set
    end
  end
end

path = Pathname.new(File.expand_path(File.dirname(__FILE__))) + 'runner'
require path + 'single_threaded'
