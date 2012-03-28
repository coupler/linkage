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

        attr_reader :kind, :side, :lhs, :rhs

        def initialize(dsl, type, lhs)
          @dsl = dsl
          @type = type
          @lhs = lhs
          @rhs = nil
          @side = nil
          @kind = nil
        end

        VALID_OPERATORS.each do |operator|
          define_method(operator) do |rhs|
            # NOTE: lhs is always a DataWrapper

            @rhs = rhs
            if !@rhs.is_a?(DataWrapper) || @lhs.static? || @rhs.static? || @lhs.side == @rhs.side
              @side = @lhs.side
              @side = @rhs.side if @side.nil? && @rhs.is_a?(DataWrapper)
              @kind = :filter
            elsif @lhs.same_except_side?(@rhs)
              @kind = :self
            elsif @lhs.dataset == @rhs.dataset
              @kind = :cross
            else
              @kind = :dual
            end
            @operator = @type == :must_not ? OPERATOR_OPPOSITES[operator] : operator
            @dsl.add_expectation(self)
          end
        end

        def merged_field
          @merged_field ||= @lhs.data.merge(@rhs.data)
        end

        def filter_expr
          if @filter_expr.nil? && @kind == :filter
            if @lhs.is_a?(DataWrapper) && !@lhs.static?
              target = @lhs
              other = @rhs
            elsif @rhs.is_a?(DataWrapper) && !@rhs.static?
              target = @rhs
              other = @lhs
            else
              raise "Wonky filter"
            end

            arg1 = target.to_expr(@side)
            arg2 = other.is_a?(DataWrapper) ? other.to_expr(@side) : other
            @filter_expr =
              case @operator
              when :==
                { arg1 => arg2 }
              when :'!='
                ~{ arg1 => arg2 }
              else
                arg1 = Sequel::SQL::Identifier.new(arg1)
                arg2 = arg2.is_a?(Symbol) ? Sequel::SQL::Identifier.new(arg2) : arg2
                Sequel::SQL::BooleanExpression.new(@operator, arg1, arg2)
              end
          end
          @filter_expr
        end

        def apply_to(dataset, side)
          if @kind == :filter
            if @side == side
              return dataset.filter(filter_expr)
            else
              # Doesn't apply
              return dataset
            end
          end

          if @lhs.is_a?(DataWrapper) && @lhs.side == side
            target = @lhs
          elsif @rhs.is_a?(DataWrapper) && @rhs.side == side
            target = @rhs
          else
            raise "Wonky expectation"
          end

          expr = target.to_expr(side)
          aliased_expr = expr
          if expr != merged_field.name
            aliased_expr = expr.as(merged_field.name)
          end

          dataset.order_more(expr).select_more(aliased_expr)
        end

        def same_filter?(other)
          kind == :filter && other.kind == :filter && filter_expr == other.filter_expr
        end
      end

      class DataWrapper
        attr_reader :side, :dataset

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
      end

      class FieldWrapper < DataWrapper
        attr_reader :name

        def initialize(dsl, side, dataset, name)
          @dsl = dsl
          @side = side
          @dataset = dataset
          @name = name
        end

        def static?
          false
        end

        def same_except_side?(other)
          other.is_a?(FieldWrapper) && name == other.name
        end

        def data
          @dataset.field_set[@name]
        end

        def to_expr(side = nil)
          data.to_expr
        end
      end

      class FunctionWrapper < DataWrapper
        attr_reader :klass, :args

        def initialize(dsl, klass, args)
          @dsl = dsl
          @klass = klass
          @args = args
          @side = nil
          @static = true
          args.each do |arg|
            if arg.kind_of?(DataWrapper)
              raise "conflicting sides" if @side && @side != arg.side
              @side = arg.side
              @static &&= arg.static?
            end
          end
        end

        def data
          @data ||= @klass.new(*@args.collect { |arg| arg.kind_of?(DataWrapper) ? arg.data : arg })
        end

        def to_expr(side)
          dataset = side == :lhs ? @dsl.lhs : @dsl.rhs
          data.to_expr(dataset.dataset.adapter_scheme)
        end

        def name
          data.name
        end

        def static?
          @static
        end

        def same_except_side?(other)
          if other.is_a?(FunctionWrapper) && klass == other.klass
            args.each_with_index do |arg, i|
              other_arg = other.args[i]
              if arg.is_a?(DataWrapper) && other_arg.is_a?(DataWrapper)
                if !arg.same_except_side?(other_arg)
                  return false
                end
              else
                if arg != other_arg
                  return false
                end
              end
            end
            return true
          end
          false
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
              if !expectation.same_filter?(other)
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
      @expectations = []
      @visual_comparisons = []
      @linkage_type = dataset_1 == dataset_2 ? :self : :dual
    end

    def configure(&block)
      DSL.new(self, &block)
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
        schema << [merged_field.name, merged_type[:type], merged_type[:opts] || {}]
      end

      schema
    end

    def result_set
      @result_set ||= ResultSet.new(self)
    end
  end
end
