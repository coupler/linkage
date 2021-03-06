require 'bundler/gem_tasks'

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
  test.warning = false
end
task :default => :test

namespace :test do
  Rake::TestTask.new(:unit) do |test|
    test.libs << 'lib' << 'test'
    test.pattern = 'test/unit/**/test_*.rb'
    test.verbose = true
    test.warning = false
  end

  Rake::TestTask.new(:integration) do |test|
    test.libs << 'lib' << 'test'
    test.pattern = 'test/integration/**/test_*.rb'
    test.verbose = true
    test.warning = false
  end
end

if RUBY_PLATFORM !~ /java/
  require 'yard'
  YARD::Rake::YardocTask.new do |t|
    t.files = ['lib/**/*.rb']
  end
end

# Yoinked from https://github.com/rails/rails/blob/master/railties/lib/rails/tasks/annotations.rake
namespace :notes do
  ['OPTIMIZE', 'FIXME', 'TODO'].each do |annotation|
    desc "Enumerate all #{annotation} annotations"
    task annotation.downcase.intern do
      SourceAnnotationExtractor.enumerate annotation
    end
  end

  desc "Enumerate a custom annotation, specify with ANNOTATION=CUSTOM"
  task :custom do
    SourceAnnotationExtractor.enumerate ENV['ANNOTATION']
  end
end

# Yoinked from https://github.com/rails/rails/blob/master/railties/lib/rails/source_annotation_extractor.rb
#
# Implements the logic behind the rake tasks for annotations like
#
#   rake notes
#   rake notes:optimize
#
# and friends. See <tt>rake -T notes</tt> and <tt>railties/lib/tasks/annotations.rake</tt>.
#
# Annotation objects are triplets <tt>:line</tt>, <tt>:tag</tt>, <tt>:text</tt> that
# represent the line where the annotation lives, its tag, and its text. Note
# the filename is not stored.
#
# Annotations are looked for in comments and modulus whitespace they have to
# start with the tag optionally followed by a colon. Everything up to the end
# of the line (or closing ERB comment tag) is considered to be their text.
class SourceAnnotationExtractor
  class Annotation < Struct.new(:line, :tag, :text)

    # Returns a representation of the annotation that looks like this:
    #
    #   [126] [TODO] This algorithm is simple and clearly correct, make it faster.
    #
    # If +options+ has a flag <tt>:tag</tt> the tag is shown as in the example above.
    # Otherwise the string contains just line and text.
    def to_s(options={})
      s = "[%3d] " % line
      s << "[#{tag}] " if options[:tag]
      s << text
    end
  end

  # Prints all annotations with tag +tag+ under the root directories +app+, +config+, +lib+,
  # +script+, and +test+ (recursively). Only filenames with extension 
  # +.builder+, +.rb+, and +.erb+ are taken into account. The +options+
  # hash is passed to each annotation's +to_s+.
  #
  # This class method is the single entry point for the rake tasks.
  def self.enumerate(tag, options={})
    extractor = new(tag)
    extractor.display(extractor.find, options)
  end

  attr_reader :tag

  def initialize(tag)
    @tag = tag
  end

  # Returns a hash that maps filenames under +dirs+ (recursively) to arrays
  # with their annotations.
  def find(dirs=%w(app config lib script test))
    dirs.inject({}) { |h, dir| h.update(find_in(dir)) }
  end

  # Returns a hash that maps filenames under +dir+ (recursively) to arrays
  # with their annotations. Only files with annotations are included, and only
  # those with extension +.builder+, +.rb+, +.erb+, +.haml+, +.slim+ and +.coffee+
  # are taken into account.
  def find_in(dir)
    results = {}

    Dir.glob("#{dir}/*") do |item|
      next if File.basename(item)[0] == ?.

      if File.directory?(item)
        results.update(find_in(item))
      elsif item =~ /\.(builder|rb|coffee)$/
        results.update(extract_annotations_from(item, /#\s*(#{tag}):?\s*(.*)$/))
      elsif item =~ /\.erb$/
        results.update(extract_annotations_from(item, /<%\s*#\s*(#{tag}):?\s*(.*?)\s*%>/))
      elsif item =~ /\.haml$/
        results.update(extract_annotations_from(item, /-\s*#\s*(#{tag}):?\s*(.*)$/))
      elsif item =~ /\.slim$/
        results.update(extract_annotations_from(item, /\/\s*\s*(#{tag}):?\s*(.*)$/))
      end
    end

    results
  end

  # If +file+ is the filename of a file that contains annotations this method returns
  # a hash with a single entry that maps +file+ to an array of its annotations.
  # Otherwise it returns an empty hash.
  def extract_annotations_from(file, pattern)
    lineno = 0
    result = File.readlines(file).inject([]) do |list, line|
      lineno += 1
      next list unless line =~ pattern
      list << Annotation.new(lineno, $1, $2)
    end
    result.empty? ? {} : { file => result }
  end

  # Prints the mapping from filenames to annotations in +results+ ordered by filename.
  # The +options+ hash is passed to each annotation's +to_s+.
  def display(results, options={})
    results.keys.sort.each do |file|
      puts "#{file}:"
      results[file].each do |note|
        puts "  * #{note.to_s(options)}"
      end
      puts
    end
  end
end
