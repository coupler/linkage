require File.expand_path("../../test_comparators", __FILE__)

class UnitTests::TestComparators::TestStrcompare < Test::Unit::TestCase
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

  test "requires string types" do
    field_1 = stub('field 1', :name => :foo, :ruby_type => { :type => Integer })
    field_2 = stub('field 2', :name => :bar, :ruby_type => { :type => Integer })
    assert_raises do
      Strcompare.new(field_1, field_2, :jarowinkler)
    end
  end

  test "requires valid operator" do
    field_1 = stub('field 1', :name => :foo, :ruby_type => { :type => String })
    field_2 = stub('field 2', :name => :bar, :ruby_type => { :type => String })
    assert_raises do
      Strcompare.new(field_1, field_2, 'foo')
    end
  end

  test "score for jarowinkler" do
    field_1 = stub('field 1', :name => :foo, :ruby_type => { :type => String })
    field_2 = stub('field 2', :name => :bar, :ruby_type => { :type => String })
    comp = Strcompare.new(field_1, field_2, :jarowinkler)
    assert_equal 0.961, comp.score({:foo => 'martha'}, {:bar => 'marhta'})
    assert_equal 0.840, comp.score({:foo => 'dwayne'}, {:bar => 'duane'})
    assert_equal 0.813, comp.score({:foo => 'dixon'}, {:bar => 'dicksonx'})
    assert_equal 0, comp.score({:foo => 'cat'}, {:bar => 'dog'})
  end

  test "score for damerau-levenshtein" do
    field_1 = stub('field 1', :name => :foo, :ruby_type => { :type => String })
    field_2 = stub('field 2', :name => :bar, :ruby_type => { :type => String })
    comp = Strcompare.new(field_1, field_2, :damerau_levenshtein)
    assert_equal 0.833, comp.score({:foo => 'martha'}, {:bar => 'marhta'})
    assert_equal 0.750, comp.score({:foo => 'dwayne'}, {:bar => 'duane'})
    assert_equal 0.688, comp.score({:foo => 'dixon'}, {:bar => 'dicksonx'})
    assert_equal 0.889, comp.score({:foo => 'perfect'}, {:bar => 'perfect10'})
    assert_equal 0, comp.score({:foo => 'cat'}, {:bar => 'dog'})
  end

  test "registers itself" do
    assert_equal Strcompare, Linkage::Comparator['strcompare']
  end
end
