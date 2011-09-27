require 'helper'

class UnitTests::TestDataset < Test::Unit::TestCase
  def setup
    @database = stub("database")
    Sequel.stubs(:connect).yields(@database)
    @schema = [
      [:id, {:allow_null=>true, :default=>nil, :primary_key=>true, :db_type=>"integer", :type=>:integer, :ruby_default=>nil}],
      [:first_name, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(255)", :type=>:string, :ruby_default=>nil}],
      [:last_name, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(255)", :type=>:string, :ruby_default=>nil}]
    ]
    @database.stubs(:schema).returns(@schema)
    @dataset = stub("dataset")
    @database.stubs(:[]).returns(@dataset)

    @id_field = stub("id field", :dataset= => nil, :name => :id)
    Linkage::Field.stubs(:new).with(:id, kind_of(Hash)).returns(@id_field)
    @first_name_field = stub("first_name field", :dataset= => nil, :name => :first_name)
    Linkage::Field.stubs(:new).with(:first_name, kind_of(Hash)).returns(@first_name_field)
    @last_name_field = stub("last_name field", :dataset= => nil, :name => :last_name)
    Linkage::Field.stubs(:new).with(:last_name, kind_of(Hash)).returns(@last_name_field)
  end

  def expr(&block)
    Sequel.virtual_row(&block)
  end

  test "initialize with uri and table name" do
    Sequel.expects(:connect).with("foo:/bar", {}).yields(@database)
    @database.expects(:schema).with(:baz).returns(@schema)
    primary_key_field = mock(:dataset= => nil)
    Linkage::Field.expects(:new).with(*@schema[0]).returns(primary_key_field)
    Linkage::Field.expects(:new).with(*@schema[1]).returns(mock(:dataset= => nil))
    Linkage::Field.expects(:new).with(*@schema[2]).returns(mock(:dataset= => nil))

    ds = Linkage::Dataset.new("foo:/bar", "baz")
    assert_equal primary_key_field, ds.primary_key
  end

  test "initialize with sequel options" do
    Sequel.expects(:connect).with("foo:/bar", :junk => 123).yields(@database)
    ds = Linkage::Dataset.new("foo:/bar", "baz", :junk => 123)
  end

  test "dataset id increments" do
    dataset_1 = Linkage::Dataset.new("foo:/bar", "baz")
    assert_kind_of Fixnum, dataset_1.id
    dataset_2 = Linkage::Dataset.new("foo:/qux", "corge")
    assert_equal dataset_1.id + 1, dataset_2.id
  end

  test "== compares uri and table name" do
    dataset_1 = Linkage::Dataset.new("foo:/bar", "baz")
    dataset_2 = Linkage::Dataset.new("foo:/bar", "baz")
    dataset_3 = Linkage::Dataset.new("foo:/qux", "corge")
    assert_equal dataset_1, dataset_2
    assert_not_equal dataset_1, dataset_3
  end

  test "dup" do
    dataset_1 = Linkage::Dataset.new("foo:/bar", "baz")

    ds = stub('new dataset')
    Linkage::Dataset.expects(:new).with('foo:/bar', :baz).returns(ds)
    dataset_2 = dataset_1.dup
    assert_equal ds, dataset_2
  end

  test "clone doesn't shallow copy fields" do
    field_1 = stub('field 1', :name => :id, :dataset= => nil)
    Linkage::Field.expects(:new).with(*@schema[0]).returns(field_1)
    field_2 = stub('field 2', :dataset= => nil)
    Linkage::Field.expects(:new).with(*@schema[1]).returns(field_2)
    field_3 = stub('field 3', :dataset= => nil)
    Linkage::Field.expects(:new).with(*@schema[2]).returns(field_3)
    dataset_1 = Linkage::Dataset.new("foo:/bar", "baz")

    field_1.expects(:clone).returns(mock('field 1 clone', :dataset= => nil))
    field_2.expects(:clone).returns(mock('field 2 clone', :dataset= => nil))
    field_3.expects(:clone).returns(mock('field 3 clone', :dataset= => nil))
    dataset_2 = dataset_1.clone
    dataset_2.fields.each_pair do |name, field|
      assert !field.equal?(dataset_1.fields[name])
    end
    assert !dataset_2.primary_key.equal?(dataset_1.primary_key)
    assert_equal dataset_1.id, dataset_2.id
  end

  test "clone doesn't shallow copy @order" do
    dataset_1 = Linkage::Dataset.new("foo:/bar", "baz")
    dataset_2 = dataset_1.clone
    dataset_1.add_order(@first_name_field)
    assert_empty dataset_2.instance_variable_get(:@order)
  end

  test "clone doesn't shallow copy @select" do
    dataset_1 = Linkage::Dataset.new("foo:/bar", "baz")
    dataset_2 = dataset_1.clone
    dataset_1.add_select(@first_name_field)
    assert_empty dataset_2.instance_variable_get(:@select)
  end

  test "clone doesn't shallow copy @filter" do
    dataset_1 = Linkage::Dataset.new("foo:/bar", "baz")
    dataset_2 = dataset_1.clone
    dataset_1.add_filter(@first_name_field, :==, "foo")
    assert_empty dataset_2.instance_variable_get(:@filter)
  end

  test "add_order, then each" do
    field = stub('field', :name => :last_name)
    ds = Linkage::Dataset.new("foo:/bar", "baz")
    ds.add_order(field)
    @dataset.expects(:order).with(:last_name).returns(@dataset)
    row = {:id => 123, :last_name => 'foo'}
    @dataset.expects(:each).yields(row)

    ran = false
    ds.each do |yielded_row|
      ran = true
      assert_equal({:pk => 123, :values => {:last_name => 'foo'}}, yielded_row)
    end
    assert ran
  end

  test "add_order descending, then each" do
    field = stub('field', :name => :last_name)
    ds = Linkage::Dataset.new("foo:/bar", "baz")
    ds.add_order(field, :desc)
    @dataset.expects(:order).with(:last_name.desc).returns(@dataset)
    row = {:id => 123, :last_name => 'foo'}
    @dataset.expects(:each).yields(row)

    ran = false
    ds.each do |yielded_row|
      ran = true
      assert_equal({:pk => 123, :values => {:last_name => 'foo'}}, yielded_row)
    end
    assert ran
  end

  test "add_order weeds out duplicates" do
    field = stub('field', :name => :last_name)
    ds = Linkage::Dataset.new("foo:/bar", "baz")
    ds.add_order(field)
    ds.add_order(field)
    @dataset.expects(:order).with(:last_name).returns(@dataset)
    @dataset.expects(:each)
    ds.each { }
  end

  test "add_select, then each" do
    field = stub('field', :name => :last_name)
    ds = Linkage::Dataset.new("foo:/bar", "baz")
    ds.add_select(field)
    @dataset.expects(:select).with(:id, :last_name).returns(@dataset)
    row = {:id => 123, :last_name => 'foo'}
    @dataset.expects(:each).yields(row)

    ran = false
    ds.each do |yielded_row|
      ran = true
      assert_equal({:pk => 123, :values => {:last_name => 'foo'}}, yielded_row)
    end
    assert ran
  end

  test "add_select with an alias, then each" do
    field = stub('field', :name => :last_name)
    ds = Linkage::Dataset.new("foo:/bar", "baz")
    ds.add_select(field, :junk)
    @dataset.expects(:select).with(:id, :last_name.as(:junk)).returns(@dataset)
    row = {:id => 123, :junk => 'foo'}
    @dataset.expects(:each).yields(row)

    ran = false
    ds.each do |yielded_row|
      ran = true
      assert_equal({:pk => 123, :values => {:junk => 'foo'}}, yielded_row)
    end
    assert ran
  end

  test "add_select weeds out duplicates" do
    field = stub('field', :name => :last_name)
    ds = Linkage::Dataset.new("foo:/bar", "baz")
    ds.add_select(field)
    ds.add_select(field)
    @dataset.expects(:select).with(:id, :last_name).returns(@dataset)
    @dataset.expects(:each)
    ds.each { }
  end

  test "add_filter with :==, then each" do
    field = stub('field', :name => :age)
    ds = Linkage::Dataset.new("foo:/bar", "baz")
    ds.add_filter(field, :==, 30)
    @dataset.expects(:filter).with(:age => 30).returns(@dataset)
    row = {:id => 123, :junk => 'foo'}
    @dataset.expects(:each).yields(row)

    ran = false
    ds.each do |yielded_row|
      ran = true
      assert_equal({:pk => 123, :values => {:junk => 'foo'}}, yielded_row)
    end
    assert ran
  end

  test "add_filter with :== between two fields, then each" do
    field_1 = stub_field('field 1', :name => :foo)
    field_2 = stub_field('field 2', :name => :bar)
    ds = Linkage::Dataset.new("foo:/bar", "baz")
    ds.add_filter(field_1, :==, field_2)
    @dataset.expects(:filter).with(:foo => :bar).returns(@dataset)
    @dataset.expects(:each)
    ds.each { }
  end

  test "add_filter with :>, then each" do
    field = stub('field', :name => :age)
    ds = Linkage::Dataset.new("foo:/bar", "baz")
    ds.add_filter(field, :>, 30)
    @dataset.expects(:filter).with(expr{age > 30}).returns(@dataset)
    @dataset.expects(:each)
    ds.each { }
  end

  test "add_filter with :<, then each" do
    field = stub('field', :name => :age)
    ds = Linkage::Dataset.new("foo:/bar", "baz")
    ds.add_filter(field, :<, 30)
    @dataset.expects(:filter).with(expr{age < 30}).returns(@dataset)
    @dataset.expects(:each)
    ds.each { }
  end

  test "add_filter with :>=, then each" do
    field = stub('field', :name => :age)
    ds = Linkage::Dataset.new("foo:/bar", "baz")
    ds.add_filter(field, :>=, 30)
    @dataset.expects(:filter).with(expr{age >= 30}).returns(@dataset)
    @dataset.expects(:each)
    ds.each { }
  end

  test "add_filter with :<=, then each" do
    field = stub('field', :name => :age)
    ds = Linkage::Dataset.new("foo:/bar", "baz")
    ds.add_filter(field, :<=, 30)
    @dataset.expects(:filter).with(expr{age <= 30}).returns(@dataset)
    @dataset.expects(:each)
    ds.each { }
  end

  test "add_filter with :!=, then each" do
    field = stub('field', :name => :age)
    ds = Linkage::Dataset.new("foo:/bar", "baz")
    ds.add_filter(field, :'!=', 30)
    @dataset.expects(:filter).with(~{:age => 30}).returns(@dataset)
    @dataset.expects(:each)
    ds.each { }
  end

  test "add_filter with :> field, then each" do
    field_1 = stub_field('field 1', :name => :age)
    field_2 = stub_field('field 2', :name => :age_2)
    ds = Linkage::Dataset.new("foo:/bar", "baz")
    ds.add_filter(field_1, :>, field_2)
    @dataset.expects(:filter).with(expr{age > age_2}).returns(@dataset)
    @dataset.expects(:each)
    ds.each { }
  end
end
