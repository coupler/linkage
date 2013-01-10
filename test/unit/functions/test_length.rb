require 'helper'

class UnitTests::TestLength < Test::Unit::TestCase
  test "subclass of Function" do
    assert_equal Linkage::Function, Linkage::Functions::Length.superclass
  end

  test "ruby_type for string literal" do
    length = Linkage::Functions::Length.new("foo", :dataset => stub('dataset'))
    assert_equal({:type => Fixnum}, length.ruby_type)
  end

  test "ruby_type for string field" do
    field_1 = stub_field('field 1', :name => :bar, :ruby_type => {:type => String}, :dataset => stub('dataset'))
    assert_equal({:type => Fixnum}, Linkage::Functions::Length.new(field_1).ruby_type)

    field_2 = stub_field('field 2', :name => :bar, :ruby_type => {:type => String, :opts => {:size => 123}}, :dataset => stub('dataset'))
    assert_equal({:type => Fixnum}, Linkage::Functions::Length.new(field_2).ruby_type)
  end

  test "ruby_type for string function" do
    func = new_function('foo', {:type => String, :opts => {:junk => '123'}})
    assert_equal({:type => Fixnum}, Linkage::Functions::Length.new(func.new(:dataset => stub('dataset'))).ruby_type)
  end

  test "parameters" do
    assert_equal [[String]], Linkage::Functions::Length.parameters
  end

  test "name" do
    assert_equal "length", Linkage::Functions::Length.function_name
  end

  test "to_expr for sqlite" do
    func = Linkage::Functions::Length.new("foo bar", :dataset => stub('dataset', :database_type => :sqlite))
    assert_equal :length.sql_function("foo bar"), func.to_expr
  end

  test "to_expr for mysql" do
    func = Linkage::Functions::Length.new("foo bar", :dataset => stub('dataset', :database_type => :mysql))
    assert_equal :char_length.sql_function("foo bar"), func.to_expr
  end

  test "to_expr for postgresql" do
    func = Linkage::Functions::Length.new("foo bar", :dataset => stub('dataset', :database_type => :postgres))
    assert_equal :char_length.sql_function("foo bar"), func.to_expr
  end

  test "registers itself" do
    assert_equal Linkage::Function["length"], Linkage::Functions::Length
  end
end
