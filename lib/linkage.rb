require 'pathname'
require 'fileutils'
require 'delegate'
require 'sequel'
require 'hashery'
require 'observer'

module Linkage
end

path = Pathname.new(File.expand_path(File.dirname(__FILE__))) + 'linkage'
require path + 'comparator'
require path + 'configuration'
require path + 'dataset'
require path + 'field'
require path + 'field_set'
require path + 'import_buffer'
require path + 'match_recorder'
require path + 'match_set'
require path + 'matcher'
require path + 'result_set'
require path + 'runner'
require path + 'score_recorder'
require path + 'score_set'
require path + 'version'
require path + 'warnings'

Sequel.extension :core_extensions
