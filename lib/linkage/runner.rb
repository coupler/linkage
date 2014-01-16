module Linkage
  # Use this class to run a configuration created by {Dataset#link_with}.
  class Runner
    attr_reader :config

    # @param [Linkage::Configuration] config
    # @see Dataset#link_with
    def initialize(config)
      @config = config
    end

    # @abstract
    def execute
      raise NotImplementedError
    end
  end
end

path = Pathname.new(File.expand_path(File.dirname(__FILE__))) + 'runners'
require path + 'single_threaded'
