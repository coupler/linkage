require 'helper'

class UnitTests::TestTrim < Test::Unit::TestCase
  test "subclass of Function" do
    assert_equal Linkage::Function, Linkage::Functions::Trim.superclass
  end

  test "ruby_type for string literal" do
    assert_equal({:type => String}, Linkage::Functions::Trim.new("foo").ruby_type)
  end

  test "ruby_type for string field" do
    field_1 = stub_field('field 1', :name => :bar, :ruby_type => {:type => String})
    assert_equal({:type => String}, Linkage::Functions::Trim.new(field_1).ruby_type)

    field_2 = stub_field('field 2', :name => :bar, :ruby_type => {:type => String, :opts => {:size => 123}})
    assert_equal({:type => String, :opts => {:size => 123}}, Linkage::Functions::Trim.new(field_2).ruby_type)
  end

  test "ruby_type for string function" do
    func = new_function('foo', {:type => String, :opts => {:junk => '123'}})
    assert_equal({:type => String, :opts => {:junk => '123'}}, Linkage::Functions::Trim.new(func.new).ruby_type)
  end

  test "parameters" do
    assert_equal [[String]], Linkage::Functions::Trim.parameters
  end

  test "name" do
    assert_equal "trim", Linkage::Functions::Trim.function_name
  end

  test "registers itself" do
    assert_equal Linkage::Function["trim"], Linkage::Functions::Trim
  end
end
