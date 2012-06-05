# -*- encoding: utf-8 -*-
require File.expand_path('../lib/linkage/version', __FILE__)

Gem::Specification.new do |gem|
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
  gem.add_dependency "sequel-collation"
end
