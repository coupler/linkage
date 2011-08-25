require 'pathname'
require 'sequel'

module Linkage
end

path = Pathname.new(File.expand_path(File.dirname(__FILE__))) + 'linkage'
require path + 'utils'
require path + 'dataset'
require path + 'configuration'
require path + 'runner'
