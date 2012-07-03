require 'helper'

class UnitTests::TestBinary < Test::Unit::TestCase
  def self.const_missing(name)
    if Linkage::Functions.const_defined?(name)
      Linkage::Functions.const_get(name)
    else
      super
    end
  end

  test "subclass of Function" do
    assert_equal Linkage::Function, Linkage::Functions::Binary.superclass
  end

  test "ruby_type" do
    expected = {:type => File}
    assert_equal(expected, Linkage::Functions::Binary.new("foo").ruby_type)
    field = stub_field('field 1', :name => :bar, :ruby_type => {:type => String})
    assert_equal(expected, Linkage::Functions::Binary.new(field).ruby_type)
  end

  test "parameters" do
    assert_equal [[String]], Linkage::Functions::Binary.parameters
  end

  test "name" do
    assert_equal "binary", Linkage::Functions::Binary.function_name
  end

  test "registers itself" do
    assert_equal Linkage::Function["binary"], Linkage::Functions::Binary
  end

  test "to_expr for sqlite" do
    args = ["foo"]
    func = Binary.new(*args)
    assert_equal "foo".cast(:blob), func.to_expr(:sqlite)
  end

  test "to_expr for mysql" do
    args = ["foo"]
    func = Binary.new(*args)
    assert_equal "foo".cast(:binary), func.to_expr(:mysql)
  end

  test "to_expr for postgresql" do
    args = ["foo"]
    func = Binary.new(*args)
    assert_equal "foo".cast(:bytea), func.to_expr(:postgres)
  end
end
