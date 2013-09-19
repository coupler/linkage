require 'helper'

class UnitTests::TestStrcompare < Test::Unit::TestCase
  def self.const_missing(name)
    if Linkage::Comparators.const_defined?(name)
      Linkage::Comparators.const_get(name)
    else
      super
    end
  end

  test "subclass of Comparator" do
    assert_equal Linkage::Comparator, Strcompare.superclass
  end

  test "valid parameters" do
    meta_object_1 = stub('meta object', :name => :foo, :side => :lhs, :ruby_type => { :type => String }, :static? => false)
    meta_object_2 = stub('meta object', :object => 'jw', :ruby_type => { :type => String }, :static? => true, :raw? => true)
    meta_object_3 = stub('meta object', :name => :bar, :side => :rhs, :ruby_type => { :type => String }, :static? => false)
    assert_nothing_raised do
      Strcompare.new(meta_object_1, meta_object_2, meta_object_3)
    end
  end

  test "score for jarowinkler" do
    meta_object_1 = stub('meta object', :name => :foo, :side => :lhs, :ruby_type => { :type => String }, :static? => false)
    meta_object_2 = stub('meta object', :object => 'jw', :ruby_type => { :type => String }, :static? => true, :raw? => true)
    meta_object_3 = stub('meta object', :name => :bar, :side => :rhs, :ruby_type => { :type => String }, :static? => false)
    comp = Strcompare.new(meta_object_1, meta_object_2, meta_object_3)
    assert_equal 0.961, comp.score({:foo => 'martha'}, {:bar => 'marhta'})
    assert_equal 0.840, comp.score({:foo => 'dwayne'}, {:bar => 'duane'})
    assert_equal 0.813, comp.score({:foo => 'dixon'}, {:bar => 'dicksonx'})
    assert_equal 0, comp.score({:foo => 'cat'}, {:bar => 'dog'})
  end

  test "registers itself" do
    assert_equal Strcompare, Linkage::Comparator['strcompare']
  end

  test "requires argument from each side" do
    meta_object_1 = stub('meta object', :name => :foo, :side => :lhs, :ruby_type => { :type => String }, :static? => false)
    meta_object_2 = stub('meta object', :object => 'jw', :ruby_type => { :type => String }, :static? => true, :raw? => true)
    meta_object_3 = stub('meta object', :name => :bar, :side => :lhs, :ruby_type => { :type => String }, :static? => false)
    assert_raises do
      Strcompare.new(meta_object_1, meta_object_2, meta_object_3)
    end
  end

  test "requires that 1st argument is a String" do
    meta_object_1 = stub('meta object', :name => :foo, :side => :lhs, :ruby_type => { :type => Date }, :static? => false)
    meta_object_2 = stub('meta object', :object => '>=', :ruby_type => { :type => String }, :static? => true, :raw? => true)
    meta_object_3 = stub('meta object', :name => :bar, :side => :rhs, :ruby_type => { :type => String }, :static? => false)
    assert_raises do
      Strcompare.new(meta_object_1, meta_object_2, meta_object_3)
    end
  end

  test "requires that 3rd argument is a String" do
    meta_object_1 = stub('meta object', :name => :foo, :side => :lhs, :ruby_type => { :type => String }, :static? => false)
    meta_object_2 = stub('meta object', :object => '>=', :ruby_type => { :type => String }, :static? => true, :raw? => true)
    meta_object_3 = stub('meta object', :name => :bar, :side => :rhs, :ruby_type => { :type => Date }, :static? => false)
    assert_raises do
      Strcompare.new(meta_object_1, meta_object_2, meta_object_3)
    end
  end

  test "requires raw operator to be jw" do
    meta_object_1 = stub('meta object', :name => :foo, :side => :lhs, :ruby_type => { :type => String }, :static? => false)
    meta_object_2 = stub('meta object', :object => 'foo', :ruby_type => { :type => String }, :static? => true, :raw? => true)
    meta_object_3 = stub('meta object', :name => :bar, :side => :rhs, :ruby_type => { :type => String }, :static? => false)
    assert_raises do
      Strcompare.new(meta_object_1, meta_object_2, meta_object_3)
    end
  end
end
