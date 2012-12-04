module Linkage
  # The Expectation class contains information about how two datasets
  # should be linked.
  class Expectation
  end
end

Dir.glob(File.expand_path(File.join(File.dirname(__FILE__), "expectations", "*.rb"))).each do |filename|
  require filename
end
