require 'helper'

class UnitTests::TestGroup < Test::Unit::TestCase
  test "initialize" do
    g = Linkage::Group.new({:test => 'test'}, {:count => 1, :id => 456})
    assert_equal({:test => 'test'}, g.values)
    assert_equal 1, g.count
    assert_equal 456, g.id
  end

  test "decollate strings" do
    test_ruby_type = { :type => String, :opts => { :collate => :latin1_swedish_ci } }
    group = Linkage::Group.new({:test => 'TeSt '}, {
      :count => 1, :id => 456, :ruby_types => { :test => test_ruby_type },
      :database_type => :mysql
    })
    assert_equal({:test => "TEST"}, group.decollated_values)
  end

  test "don't decollate non-strings or strings without collation information" do
    ruby_types = {
      :foo => {
        :type => String, :opts => { :collate => :latin1_swedish_ci }
      },
      :bar => {
        :type => Fixnum
      },
      :baz => {
        :type => String
      }
    }
    group = Linkage::Group.new({:foo => 'foO', :bar => 123, :baz => "foO"}, {
      :count => 1, :id => 456, :ruby_types => ruby_types,
      :database_type => :mysql
    })
    assert_equal({:foo => "FOO", :bar => 123, :baz => "foO"}, group.decollated_values)
  end
end
