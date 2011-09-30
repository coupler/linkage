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

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'linkage'

class Test::Unit::TestCase
  def stub_field(name, options = {}, &block)
    f = Linkage::Field.allocate
    f.stubs(options)
    if block
      f.send(:instance_eval, &block)
    end
    f.stubs(:is_a?).returns(false)
    f.stubs(:is_a?).with(Linkage::Field).returns(true)
    f
  end

  def self.current_ruby_version
    @current_ruby_version ||= Versionomy.parse(RUBY_VERSION)
  end

  def self.ruby19
    @ruby19 ||= Versionomy.parse("1.9")
  end
end

module UnitTests; end
module IntegrationTests; end
