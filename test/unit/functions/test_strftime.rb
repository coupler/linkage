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
    assert_equal(expected, Linkage::Functions::Strftime.new(Time.now, format).ruby_type)
    field = stub_field('field 1', :name => :bar, :ruby_type => {:type => Time})
    assert_equal(expected, Linkage::Functions::Strftime.new(field, format).ruby_type)
    func = new_function('foo', {:type => Time, :opts => {:junk => '123'}})
    assert_equal(expected, Linkage::Functions::Strftime.new(func.new, format).ruby_type)
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

  test "to_expr for sqlite" do
    args = [Time.now, "%Y-%m-%d"]
    func = Strftime.new(*args)
    assert_equal :strftime.sql_function(args[1], args[0]), func.to_expr(:sqlite)
  end

  test "to_expr for mysql" do
    args = [Time.now, "%Y-%m-%d"]
    func = Strftime.new(*args)
    assert_equal :date_format.sql_function(*args), func.to_expr(:mysql)
    assert_equal :date_format.sql_function(*args), func.to_expr(:mysql2)
  end

  test "to_expr for postgresql" do
    args = [Time.now, "%Y-%m-%d"]
    func = Strftime.new(*args)
    assert_equal :to_char.sql_function(*args), func.to_expr(:postgres)
  end
end
