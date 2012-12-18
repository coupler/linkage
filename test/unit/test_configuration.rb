require 'helper'

class UnitTests::TestConfiguration < Test::Unit::TestCase
  test "result_set" do
    dataset_1 = stub('dataset')
    dataset_2 = stub('dataset')
    c = Linkage::Configuration.new(dataset_1, dataset_2)

    result_set = stub('result set')
    Linkage::ResultSet.expects(:new).with(c).returns(result_set)
    assert_equal result_set, c.result_set
  end

  test "groups_table_needed? is false if there are no simple expectations" do
    dataset_1 = stub('dataset')
    dataset_2 = stub('dataset')
    conf = Linkage::Configuration.new(dataset_1, dataset_2)
    assert !conf.groups_table_needed?
  end

  test "groups_table_needed? is true if there are any simple expectations" do
    dataset_1 = stub('dataset')
    dataset_2 = stub('dataset')
    conf = Linkage::Configuration.new(dataset_1, dataset_2)
    exp = stub('simple expectation', :decollation_needed? => false)
    conf.add_simple_expectation(exp)
    assert conf.groups_table_needed?
  end

  test "scores_table_needed? is false if there are no exhaustive expectations" do
    dataset_1 = stub('dataset')
    dataset_2 = stub('dataset')
    conf = Linkage::Configuration.new(dataset_1, dataset_2)
    assert !conf.scores_table_needed?
  end

  test "scores_table_needed? is true if there are any exhaustive expectations" do
    dataset_1 = stub('dataset')
    dataset_2 = stub('dataset')
    conf = Linkage::Configuration.new(dataset_1, dataset_2)
    exp = stub('exhaustive expectation')
    conf.add_exhaustive_expectation(exp)
    assert conf.scores_table_needed?
  end

  test "scores_table_schema" do
    dataset_1 = stub('dataset 1', {
      :field_set => stub('field set 1', {
        :primary_key => stub('primary key 1', {
          :ruby_type => {:type => Integer}
        })
      })
    })
    dataset_2 = stub('dataset 2', {
      :field_set => stub('field set 2', {
        :primary_key => stub('primary key 2', {
          :ruby_type => {:type => String, :opts => {:size => 10}}
        })
      })
    })
    conf = Linkage::Configuration.new(dataset_1, dataset_2)
    exp_1 = stub('exhaustive expectation 1')
    exp_2 = stub('exhaustive expectation 2')
    conf.add_exhaustive_expectation(exp_1)
    conf.add_exhaustive_expectation(exp_2)

    expected = [
      [:id, Integer, {:primary_key => true}],
      [:record_1_id, Integer, {}],
      [:record_2_id, String, {:size => 10}],
      [:score_1, Integer, {}],
      [:score_2, Integer, {}]
    ]
    assert_equal expected, conf.scores_table_schema
  end
end
