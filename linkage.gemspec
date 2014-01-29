# -*- encoding: utf-8 -*-
require File.expand_path('../lib/linkage/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "linkage"
  gem.authors       = ["Jeremy Stephens"]
  gem.email         = ["jeremy.f.stephens@vanderbilt.edu"]
  gem.description   = %q{Performs record linkage between one or two datasets, using Sequel on the backend}
  gem.summary       = %q{Record linkage library}
  gem.homepage      = "http://github.com/coupler/linkage"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "linkage"
  gem.require_paths = ["lib"]
  gem.version       = Linkage::VERSION

  gem.add_dependency "sequel"
  gem.add_dependency "hashery"

  gem.add_development_dependency "bundler", "~> 1.3"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "test-unit"
  gem.add_development_dependency "mocha"
  gem.add_development_dependency "versionomy"
  gem.add_development_dependency "sqlite3"
  gem.add_development_dependency "mysql2"
  gem.add_development_dependency "guard-test"
  gem.add_development_dependency "guard-yard"
end
