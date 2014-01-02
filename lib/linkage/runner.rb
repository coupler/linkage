module Linkage
  # Use this class to run a configuration created by {Dataset#link_with}.
  class Runner
    attr_reader :config, :result_set

    # @param [Linkage::Configuration] config
    # @param [Linkage::ResultSet] result_set
    # @see Dataset#link_with
    def initialize(config, result_set)
      @config = config
      @result_set = result_set
    end

    # @abstract
    def execute
      raise NotImplementedError
    end
  end
end

path = Pathname.new(File.expand_path(File.dirname(__FILE__))) + 'runners'
require path + 'single_threaded'
