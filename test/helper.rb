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
require 'mocha'
require 'tmpdir'
require 'logger'
require 'pp'
require 'versionomy'
#require 'pry'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'linkage'

class Test::Unit::TestCase
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


  def self.current_ruby_version
    @current_ruby_version ||= Versionomy.parse(RUBY_VERSION)
  end

  def self.ruby19
    @ruby19 ||= Versionomy.parse("1.9")
  end

  def test_config
    @test_config ||= YAML.load_file(File.join(File.dirname(__FILE__), "config.yml"))
  end
end

module UnitTests; end
module IntegrationTests; end
