module Linkage
  class Error < Exception; end
  class FileExistsError < Error; end
  class FileMissingError < Error; end
end
