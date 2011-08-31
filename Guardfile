guard 'test' do
  watch(%r{^lib/linkage/runner/([^/]+)\.rb$}) { |m| "test/unit/test_#{m[1]}_runner.rb" }
  watch(%r{^lib/linkage/([^/]+)\.rb$}) { |m| "test/unit/test_#{m[1]}.rb" }
  watch(%r{^test/unit/test_.+\.rb$})
  watch(%r{^test/integration/test_.+\.rb$})
  watch('lib/linkage/configuration.rb') { "test/unit/test_dataset.rb" }
  watch('test/helper.rb')  { "test" }
end

guard 'yard' do
  watch(%r{lib/[^.].*\.rb$})
end
