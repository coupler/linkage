require 'helper'

class UnitTests::TestCast < Test::Unit::TestCase
  def self.const_missing(name)
    if Linkage::Functions.const_defined?(name)
      Linkage::Functions.const_get(name)
    else
      super
    end
  end

  test "subclass of Function" do
    assert_equal Linkage::Function, Linkage::Functions::Cast.superclass
  end

  test "parameters" do
    assert_equal [[:any], [String]], Linkage::Functions::Cast.parameters
  end

  test "name" do
    assert_equal "cast", Linkage::Functions::Cast.function_name
  end

  test "ruby_type when casting to (signed) integer" do
    expected = {:type => Fixnum}
    assert_equal(expected, Linkage::Functions::Cast.new('123', 'integer', :dataset => stub('dataset')).ruby_type)
    field = stub_field('field 1', :name => :bar, :ruby_type => {:type => String}, :dataset => stub('dataset'))
    assert_equal(expected, Linkage::Functions::Cast.new(field, 'integer').ruby_type)
  end

  test "ruby_type when casting to binary" do
    expected = {:type => File}
    assert_equal(expected, Linkage::Functions::Cast.new('123', 'binary', :dataset => stub('dataset')).ruby_type)
    field = stub_field('field 1', :name => :bar, :ruby_type => {:type => String}, :dataset => stub('dataset'))
    assert_equal(expected, Linkage::Functions::Cast.new(field, 'binary').ruby_type)
  end

  test "registers itself" do
    assert_equal Linkage::Function["cast"], Linkage::Functions::Cast
  end

  test "to_expr for integer (sqlite)" do
    func = Cast.new('foo', 'integer', :dataset => stub('dataset', :database_type => :sqlite))
    assert_equal 'foo'.cast(:integer), func.to_expr
  end

  test "to_expr for integer (mysql)" do
    func = Cast.new('foo', 'integer', :dataset => stub('dataset', :database_type => :mysql))
    assert_equal 'foo'.cast(:signed), func.to_expr
  end

  test "to_expr for integer (postgres)" do
    func = Cast.new('foo', 'integer', :dataset => stub('dataset', :database_type => :postgres))
    assert_equal 'foo'.cast(:integer), func.to_expr
  end

  test "to_expr for integer (h2)" do
    func = Cast.new('foo', 'integer', :dataset => stub('dataset', :database_type => :h2))
    assert_equal 'foo'.cast(:integer), func.to_expr
  end

  test "to_expr for binary (sqlite)" do
    func = Cast.new('foo', 'binary', :dataset => stub('dataset', :database_type => :sqlite))
    assert_equal 'foo'.cast(:blob), func.to_expr
  end

  test "to_expr for binary (mysql)" do
    func = Cast.new('foo', 'binary', :dataset => stub('dataset', :database_type => :mysql))
    assert_equal 'foo'.cast(:binary), func.to_expr
  end

  test "to_expr for binary (postgres)" do
    func = Cast.new('foo', 'binary', :dataset => stub('dataset', :database_type => :postgres))
    assert_equal 'foo'.cast(:bytea), func.to_expr
  end

  test "to_expr for binary (h2)" do
    func = Cast.new('foo', 'binary', :dataset => stub('dataset', :database_type => :h2))
    assert_equal 'foo'.cast(:binary), func.to_expr
  end

=begin
  test "to_expr for sqlite" do
    func = Cast.new("foo", :dataset => stub('dataset', :database_type => :sqlite))
    assert_equal "foo".cast(:blob), func.to_expr
  end

  test "to_expr for mysql" do
    func = Cast.new("foo", :dataset => stub('dataset', :database_type => :mysql))
    assert_equal "foo".cast(:binary), func.to_expr
  end

  test "to_expr for postgresql" do
    func = Cast.new("foo", :dataset => stub('dataset', :database_type => :postgres))
    assert_equal "foo".cast(:bytea), func.to_expr
  end
=end
end
