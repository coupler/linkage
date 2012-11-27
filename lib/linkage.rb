require 'pathname'
require 'delegate'
require 'sequel'

module Linkage
end

path = Pathname.new(File.expand_path(File.dirname(__FILE__))) + 'linkage'
require path + 'version'
require path + 'utils'
require path + 'warnings'
require path + 'decollation'
require path + 'dataset'
require path + 'runner'
require path + 'data'
require path + 'field'
require path + 'function'
require path + 'group'
require path + 'import_buffer'
require path + 'meta_object'
require path + 'expectation'
require path + 'configuration'
require path + 'result_set'
require path + 'field_set'
require path + 'comparator'

Sequel.extension :collation
if Sequel::Collation.respond_to?(:suppress_warnings=)
  Sequel::Collation.suppress_warnings = true
end
