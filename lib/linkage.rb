require 'pathname'
require 'delegate'
require 'sequel'
require 'hashery'
require 'observer'

module Linkage
end

path = Pathname.new(File.expand_path(File.dirname(__FILE__))) + 'linkage'
require path + 'comparator'
require path + 'configuration'
require path + 'data'
require path + 'dataset'
require path + 'decollation'
require path + 'field'
require path + 'field_set'
require path + 'function'
require path + 'import_buffer'
require path + 'match_recorder'
require path + 'match_set'
require path + 'matcher'
require path + 'runner'
require path + 'score_recorder'
require path + 'score_set'
require path + 'utils'
require path + 'version'
require path + 'warnings'

Sequel.extension :core_extensions
Sequel.extension :collation
if Sequel::Collation.respond_to?(:suppress_warnings=)
  Sequel::Collation.suppress_warnings = true
end
