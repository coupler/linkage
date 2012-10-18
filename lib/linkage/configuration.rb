module Linkage
  class Configuration
    class DSL

      # Class for visually comparing matched records
      class VisualComparisonWrapper
        attr_reader :dsl, :lhs, :rhs

        def initialize(dsl, lhs, rhs)
          @dsl = dsl
          @lhs = lhs
          @rhs = rhs

          if @lhs.is_a?(DataWrapper) && @rhs.is_a?(DataWrapper)
            if @lhs.side == @rhs.side
              raise ArgumentError, "Can't visually compare two data sources on the same side"
            end
          else
            raise ArgumentError, "Must supply two data sources for visual comparison"
          end

          @dsl.add_visual_comparison(self)
        end
      end

      class ExpectationWrapper
        VALID_OPERATORS = [:==, :>, :<, :>=, :<=]
        OPERATOR_OPPOSITES = {
          :==   => :'!=',
          :>    => :<=,
          :<=   => :>,
          :<    => :>=,
          :>=   => :<
        }

        def initialize(dsl, type, lhs)
          @dsl = dsl
          @type = type
          @lhs = lhs
        end

        VALID_OPERATORS.each do |operator|
          define_method(operator) do |rhs|
            # NOTE: lhs is always a DataWrapper

            if !rhs.is_a?(DataWrapper) || @lhs.static? || rhs.static? || @lhs.side == rhs.side
              @side = !@lhs.static? ? @lhs.side : rhs.side

              # If one of the objects in this comparison is a static function, we need to set the side
              # and the dataset based on the other object
              if rhs.is_a?(DataWrapper) && !rhs.static? && @lhs.is_a?(FunctionWrapper) && @lhs.static?
                @lhs.dataset = rhs.dataset
                @lhs.side = @side
              elsif @lhs.is_a?(DataWrapper) && !@lhs.static? && rhs.is_a?(FunctionWrapper) && rhs.static?
                rhs.dataset = @lhs.dataset
                rhs.side = @side
              end
            end
            exp_operator = @type == :must_not ? OPERATOR_OPPOSITES[operator] : operator

            rhs_meta_object = rhs.is_a?(DataWrapper) ? rhs.meta_object : MetaObject.new(rhs)
            @expectation = Expectation.create(@lhs.meta_object, rhs_meta_object, exp_operator)
            @dsl.add_expectation(@expectation)
            self
          end
        end

        def exactly
          if !@exact_match
            @expectation.exactly!
          end
        end
      end

      class DataWrapper
        attr_reader :meta_object

        def initialize
          raise NotImplementedError
        end

        [:must, :must_not].each do |type|
          define_method(type) do
            ExpectationWrapper.new(@dsl, type, self)
          end
        end

        def compare_with(other)
          VisualComparisonWrapper.new(@dsl, self, other)
        end

        def method_missing(m, *args, &block)
          if meta_object.respond_to?(m)
            meta_object.send(m, *args, &block)
          else
            super(m, *args, &block)
          end
        end
      end

      class FieldWrapper < DataWrapper
        attr_reader :name

        def initialize(dsl, side, dataset, name)
          @dsl = dsl
          @meta_object = MetaObject.new(dataset.field_set[name], side)
        end
      end

      class FunctionWrapper < DataWrapper
        def initialize(dsl, klass, args)
          @dsl = dsl

          side = dataset = nil
          static = true
          function_args = []
          args.each do |arg|
            if arg.kind_of?(DataWrapper)
              raise "conflicting sides" if side && side != arg.side
              side = arg.side
              static &&= arg.static?
              dataset = arg.dataset
              function_args << arg.object
            else
              function_args << arg
            end
          end
          @meta_object = MetaObject.new(klass.new(*function_args), side)
        end
      end

      class DatasetWrapper
        attr_reader :dataset

        def initialize(dsl, side, dataset)
          @dsl = dsl
          @dataset = dataset
          @side = side
        end

        def [](field_name)
          if @dataset.field_set.has_key?(field_name)
            FieldWrapper.new(@dsl, @side, @dataset, field_name)
          else
            raise ArgumentError, "The '#{field_name}' field doesn't exist for the #{@side} dataset!"
          end
        end
      end

      def initialize(config, &block)
        @config = config
        @lhs_filters = []
        @rhs_filters = []
        instance_eval(&block)
      end

      def lhs
        DatasetWrapper.new(self, :lhs, @config.dataset_1)
      end

      def rhs
        DatasetWrapper.new(self, :rhs, @config.dataset_2)
      end

      def save_results_in(uri, options = {})
        @config.results_uri = uri
        @config.results_uri_options = options
      end

      def add_expectation(expectation)
        @config.expectations << expectation

        if @config.linkage_type == :self
          case expectation.kind
          when :cross
            @config.linkage_type = :cross
          when :filter
            # If there different filters on both 'sides' of a self-linkage,
            # it turns into a cross linkage.
            these_filters, other_filters =
              case expectation.side
              when :lhs
                [@lhs_filters, @rhs_filters]
              when :rhs
                [@rhs_filters, @lhs_filters]
              end

            these_filters << expectation
            other_filters.each do |other|
              if !expectation.same_except_side?(other)
                @config.linkage_type = :cross
                break
              end
            end
          end
        end
      end

      def add_visual_comparison(visual_comparison)
        @config.visual_comparisons << visual_comparison
      end

      # For handling functions
      def method_missing(name, *args, &block)
        klass = Function[name.to_s]
        if klass
          FunctionWrapper.new(self, klass, args)
        else
          super
        end
      end
    end

    attr_reader :dataset_1, :dataset_2, :expectations, :visual_comparisons
    attr_accessor :linkage_type, :results_uri, :results_uri_options

    def initialize(dataset_1, dataset_2)
      @dataset_1 = dataset_1
      @dataset_2 = dataset_2
      @linkage_type = dataset_1 == dataset_2 ? :self : :dual
      @expectations = []
      @visual_comparisons = []
    end

    def configure(&block)
      DSL.new(self, &block)

      # display warnings
      results_database_warning_shown = false
      @expectations.each do |expectation|
        expectation.display_warnings
        if !results_database_warning_shown &&
            expectation.kind != :filter &&
            expectation.merged_field.ruby_type[:type] == String &&
            @dataset_1.database_type == @dataset_2.database_type

          result_set.database do |db|
            if db.database_type != @dataset_1.database_type
              warn "NOTE: Your results database (#{db.database_type}) differs from the database type of your dataset(s) (#{@dataset_1.database_type}). Because you are comparing strings, you may encounter unexpected results, as different databases compare strings differently."
              results_database_warning_shown = true
            end
          end
        end
      end
    end

    def groups_table_schema
      schema = []

      # add id
      schema << [:id, Integer, {:primary_key => true}]

      # add values
      @expectations.each do |exp|
        next  if exp.kind == :filter

        merged_field = exp.merged_field
        merged_type = merged_field.ruby_type

        # if the merged field's database type is different than the result
        # database, strip collation information
        result_db_type = nil
        result_set.database do |db|
          result_db_type = db.database_type
        end
        if merged_field.database_type != result_db_type && merged_type.has_key?(:opts)
          new_opts = merged_type[:opts].reject { |k, v| k == :collate }
          merged_type = merged_type.merge(:opts => new_opts)
        end

        col = [merged_field.name, merged_type[:type], merged_type[:opts] || {}]
        schema << col
      end

      schema
    end

    def result_set
      @result_set ||= ResultSet.new(self)
    end

    def datasets_with_applied_expectations
      dataset_1 = @dataset_1
      dataset_2 = @dataset_2
      @expectations.each do |exp|
        dataset_1 = exp.apply_to(dataset_1, :lhs)
        dataset_2 = exp.apply_to(dataset_2, :rhs) if @linkage_type != :self
      end
      @linkage_type == :self ? [dataset_1, dataset_1] : [dataset_1, dataset_2]
    end
  end
end
