# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "linkage"
  s.version = "0.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jeremy Stephens"]
  s.date = "2012-02-28"
  s.description = "Wraps Sequel to perform record linkage between one or two datasets"
  s.email = "jeremy.f.stephens@vanderbilt.edu"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.markdown"
  ]
  s.files = [
    ".document",
    ".vimrc",
    "Gemfile",
    "Gemfile.lock",
    "Guardfile",
    "LICENSE.txt",
    "README.markdown",
    "Rakefile",
    "VERSION",
    "lib/linkage.rb",
    "lib/linkage/configuration.rb",
    "lib/linkage/data.rb",
    "lib/linkage/dataset.rb",
    "lib/linkage/field.rb",
    "lib/linkage/field_set.rb",
    "lib/linkage/function.rb",
    "lib/linkage/functions/trim.rb",
    "lib/linkage/group.rb",
    "lib/linkage/import_buffer.rb",
    "lib/linkage/result_set.rb",
    "lib/linkage/runner.rb",
    "lib/linkage/runner/single_threaded.rb",
    "lib/linkage/utils.rb",
    "lib/linkage/warnings.rb",
    "linkage.gemspec",
    "test/config.yml",
    "test/helper.rb",
    "test/integration/test_cross_linkage.rb",
    "test/integration/test_dataset.rb",
    "test/integration/test_dual_linkage.rb",
    "test/integration/test_self_linkage.rb",
    "test/unit/functions/test_trim.rb",
    "test/unit/runner/test_single_threaded.rb",
    "test/unit/test_configuration.rb",
    "test/unit/test_data.rb",
    "test/unit/test_dataset.rb",
    "test/unit/test_field.rb",
    "test/unit/test_field_set.rb",
    "test/unit/test_function.rb",
    "test/unit/test_group.rb",
    "test/unit/test_import_buffer.rb",
    "test/unit/test_linkage.rb",
    "test/unit/test_result_set.rb",
    "test/unit/test_runner.rb",
    "test/unit/test_utils.rb"
  ]
  s.homepage = "http://github.com/coupler/linkage"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.3.9.4"
  s.summary = "Sequel-based record linkage"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<sequel>, [">= 0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_development_dependency(%q<test-unit>, ["= 2.3.2"])
      s.add_development_dependency(%q<mocha>, [">= 0"])
      s.add_development_dependency(%q<sqlite3>, [">= 0"])
      s.add_development_dependency(%q<yard>, [">= 0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<versionomy>, [">= 0"])
      s.add_development_dependency(%q<mysql2>, [">= 0"])
      s.add_development_dependency(%q<pry>, [">= 0"])
      s.add_development_dependency(%q<rdiscount>, [">= 0"])
      s.add_development_dependency(%q<guard-test>, [">= 0"])
      s.add_development_dependency(%q<guard-yard>, [">= 0"])
    else
      s.add_dependency(%q<sequel>, [">= 0"])
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_dependency(%q<test-unit>, ["= 2.3.2"])
      s.add_dependency(%q<mocha>, [">= 0"])
      s.add_dependency(%q<sqlite3>, [">= 0"])
      s.add_dependency(%q<yard>, [">= 0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<versionomy>, [">= 0"])
      s.add_dependency(%q<mysql2>, [">= 0"])
      s.add_dependency(%q<pry>, [">= 0"])
      s.add_dependency(%q<rdiscount>, [">= 0"])
      s.add_dependency(%q<guard-test>, [">= 0"])
      s.add_dependency(%q<guard-yard>, [">= 0"])
    end
  else
    s.add_dependency(%q<sequel>, [">= 0"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
    s.add_dependency(%q<test-unit>, ["= 2.3.2"])
    s.add_dependency(%q<mocha>, [">= 0"])
    s.add_dependency(%q<sqlite3>, [">= 0"])
    s.add_dependency(%q<yard>, [">= 0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<versionomy>, [">= 0"])
    s.add_dependency(%q<mysql2>, [">= 0"])
    s.add_dependency(%q<pry>, [">= 0"])
    s.add_dependency(%q<rdiscount>, [">= 0"])
    s.add_dependency(%q<guard-test>, [">= 0"])
    s.add_dependency(%q<guard-yard>, [">= 0"])
  end
end

