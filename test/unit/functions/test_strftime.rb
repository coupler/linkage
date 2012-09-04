require 'helper'

class UnitTests::TestStrftime < Test::Unit::TestCase
  def self.const_missing(name)
    if Linkage::Functions.const_defined?(name)
      Linkage::Functions.const_get(name)
    else
      super
    end
  end

  test "subclass of Function" do
    assert_equal Linkage::Function, Linkage::Functions::Strftime.superclass
  end

  test "ruby_type" do
    expected = {:type => String}
    format = "%Y-%m-%d"
    assert_equal(expected, Linkage::Functions::Strftime.new(Time.now, format, :dataset => stub('dataset')).ruby_type)
    field = stub_field('field 1', :name => :bar, :ruby_type => {:type => Time})
    assert_equal(expected, Linkage::Functions::Strftime.new(field, format, :dataset => stub('dataset')).ruby_type)
    func = new_function('foo', {:type => Time, :opts => {:junk => '123'}})
    assert_equal(expected, Linkage::Functions::Strftime.new(func.new(:dataset => stub('dataset')), format).ruby_type)
  end

  test "parameters" do
    assert_equal [[Date, Time, DateTime], [String]], Linkage::Functions::Strftime.parameters
  end

  test "name" do
    assert_equal "strftime", Linkage::Functions::Strftime.function_name
  end

  test "registers itself" do
    assert_equal Linkage::Function["strftime"], Linkage::Functions::Strftime
  end

  test "requires dataset" do
    func = Strftime.new(Time.now, "%Y-%m-%d")
    assert_raises(RuntimeError) { func.to_expr }
  end

  test "to_expr for sqlite" do
    now = Time.now
    func = Strftime.new(now, "%Y-%m-%d", :dataset => stub('dataset', :database_type => :sqlite))
    assert_equal :strftime.sql_function("%Y-%m-%d", now), func.to_expr
  end

  test "to_expr for mysql" do
    now = Time.now
    func = Strftime.new(now, "%Y-%m-%d", :dataset => stub('dataset', :database_type => :mysql))
    assert_equal :date_format.sql_function(now, "%Y-%m-%d"), func.to_expr
  end

  test "to_expr for postgresql" do
    now = Time.now
    func = Strftime.new(now, "%Y-%m-%d", :dataset => stub('dataset', :database_type => :postgres))
    assert_equal :to_char.sql_function(now, "%Y-%m-%d"), func.to_expr
  end
end
