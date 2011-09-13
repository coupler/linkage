module Linkage
  # Internal class used to configure linkages. See {Dataset#link_with}
  # for more information.
  class Configuration
    class ExpectationWrapper
      def initialize(type, field, config)
        @type = type
        @field = field
        @config = config
      end

      def ==(other)
        @other = other
        add_expectation(:==)
      end

      private

      def add_expectation(operator)
        klass = Expectation.get(@type)
        @config.add_expectation(klass.new(operator, @field.field, @other.field))
      end
    end

    class FieldWrapper
      attr_reader :field, :side
      def initialize(field, config)
        @field = field
        @config = config
      end

      def must
        ExpectationWrapper.new(:must, self, @config)
      end
    end

    class DatasetWrapper
      def initialize(dataset, config)
        @dataset = dataset
        @config = config
      end

      def [](field_name)
        FieldWrapper.new(@dataset.fields[field_name], @config)
      end
    end

    include Utils

    # @return [Symbol] :self or :dual
    attr_reader :linkage_type

    # @return [Array<Linkage::Expectation>]
    attr_reader :expectations

    # @return [Linkage::Dataset]
    attr_reader :dataset_1

    # @return [Linkage::Dataset]
    attr_reader :dataset_2

    def initialize(dataset_1, dataset_2)
      @dataset_1 = dataset_1
      @dataset_2 = dataset_2
      @expectations = []
      @linkage_type = dataset_1 == dataset_2 ? :self : :dual
    end

    def lhs
      @lhs ||= DatasetWrapper.new(@dataset_1, self)
    end

    def rhs
      @rhs ||= DatasetWrapper.new(@dataset_2, self)
    end

    def add_expectation(expectation)
      @expectations << expectation
    end

    def groups_table_schema
      schema = []

      # add record_id
      f = @dataset_1.primary_key.merge(@dataset_2.primary_key, :record_id)
      schema << f.ruby_type.merge(:name => f.name)

      # add group_id
      schema << {:name => :group_id, :type => Integer, :opts => {}}

      #@expectations.each do |exp|
        #if exp.kind == :join
          #new_field = exp.field_1.merge(exp.field_2)
          #schema << new_field.ruby_type.merge(:name => new_field.name)
        #end
      #end

      schema
    end

    def inspect
      to_s
    end
  end
end
