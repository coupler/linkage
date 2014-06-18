module Linkage
  # Generic error.
  class Error < Exception; end

  # Error raised when a file would be overwritten.
  class ExistsError < Error; end

  # Error raised when trying to read a file that doesn't exist.
  class MissingError < Error; end
end
