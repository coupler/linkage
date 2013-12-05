require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'test/unit'
require 'mocha/setup'
require 'tmpdir'
require 'logger'
require 'pp'
require 'versionomy'
require 'erb'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'linkage'

class Test::Unit::TestCase
  def self.current_ruby_version
    @current_ruby_version ||= Versionomy.parse(RUBY_VERSION)
  end

  def self.ruby19
    @ruby19 ||= Versionomy.parse("1.9")
  end

  @@database_config = nil
  def self.database_config
    if @@database_config.nil?
      template = File.read(File.join(File.dirname(__FILE__), "config.yml"))
      @@database_config = YAML.load(ERB.new(template).result(binding))
    end
    @@database_config
  end

  def stub_field(name, options = {}, &block)
    f = Linkage::Field.allocate
    f.stubs({:static? => false}.merge(options))
    if block
      f.send(:instance_eval, &block)
    end
    f
  end

  def stub_function(name, options = {}, &block)
    f = Linkage::Function.allocate
    f.stubs(options)
    if block
      f.send(:instance_eval, &block)
    end
    f
  end

  def stub_instance(klass, options = {}, &block)
    f = klass.allocate
    f.stubs(options)
    if block
      f.send(:instance_eval, &block)
    end
    f
  end

  def new_function(name, ruby_type = nil, params = nil, &block)
    klass = Class.new(Linkage::Function)
    klass.send(:define_singleton_method, :function_name) { name }
    if ruby_type
      klass.send(:define_method, :ruby_type) { ruby_type }
    end
    if params
      klass.send(:define_singleton_method, :parameters) { params }
    end
    klass
  end

  def new_comparator(&block)
    klass = Class.new(Linkage::Comparator)
    klass.send(:define_method, :score) { |record_1, record_2| 1 }
    if block_given?
      klass.class_eval(&block)
    end
    klass
  end

  def database_config
    self.class.database_config
  end

  def database_options_for(adapter)
    config =
      if adapter == 'sqlite'
        @tmpdir ||= Dir.mktmpdir('linkage')
        { 'adapter' => 'sqlite', 'database' => File.join(@tmpdir, "foo") }
      else
        database_config[adapter]
      end

    if config
      return config
    else
      omit("Couldn't find configuration for adapter '#{adapter}'")
    end
  end

  def database_for(adapter, options = {}, &block)
    config = database_options_for(adapter)

    if block
      Sequel.connect(config, options, &block)
    else
      Sequel.connect(config, options)
    end
  end

  def prefixed_logger(prefix)
    logger = Logger.new(STDERR)
    original_formatter = Logger::Formatter.new
    logger.formatter = proc { |severity, datetime, progname, msg|
      result = original_formatter.call(severity, datetime, progname, msg)
      "[#{prefix}] #{result}"
    }
    logger
  end

  def teardown
    if @tmpdir && File.exist?(@tmpdir)
      FileUtils.remove_entry_secure(@tmpdir)
    end
  end
end

module UnitTests; end
module IntegrationTests; end
