module Linkage
  # Delegator around Sequel::Dataset with some extra functionality.
  class Dataset
    attr_reader :field_set, :table_name
    attr_accessor :linkage_options

    def initialize(uri, table, options = {})
      @table_name = table.to_sym
      @db = Sequel.connect(uri, options)
      @db.extend(Sequel::Collation)
      @dataset = @db[@table_name]
      @field_set = FieldSet.new(self)
      @linkage_options = {}
    end

    def obj
      @dataset
    end

    def obj=(value)
      @dataset = value
    end

    # Setup a linkage with another dataset
    #
    # @return [Linkage::Configuration]
    def link_with(dataset, &block)
      conf = Configuration.new(self, dataset)
      conf.configure(&block)
      conf
    end

    def database_type
      @db.database_type
    end

    # Set objects to use for group matching. Accepts either {Linkage::MetaObject} or a
    # hash with options (valid options are :meta_object, :alias, and :cast).
    #
    # @example
    #   dataset.group_match(meta_object_1,
    #     {:meta_object => meta_object_2, :alias => :foo})
    def group_match(*args)
      args.collect! do |arg|
        case arg
        when Linkage::MetaObject
          { :meta_object => arg }
        when Hash
          if !arg.has_key?(:meta_object)
            raise ArgumentError, "Invalid option hash, missing :meta_object key"
          end
          (arg.keys - [:meta_object, :alias, :cast]).each do |invalid_key|
            warn "Invalid key in option hash: #{invalid_key}"
          end
          arg
        else
          raise ArgumentError, "expected Hash or MetaObject, got #{arg.class}"
        end
      end
      clone(:group_match => args)
    end

    # Add additional objects to use for group matching.
    def group_match_more(*args)
      args = @linkage_options[:group_match] + args  if @linkage_options[:group_match]
      group_match(*args)
    end

    def clone(new_options = {})
      new_linkage_options = {}
      new_obj_options = {}
      new_options.each_pair do |k, v|
        case k
        when :group_match
          new_linkage_options[k] = v
        else
          new_obj_options[k] = v
        end
      end
      new_obj = new_options[:new_obj]

      result = super()
      result.linkage_options = @linkage_options.merge(new_linkage_options)

      if new_obj
        result.obj = new_obj
      else
        result.obj = obj.clone(new_options)
      end

      result
    end

    def each_group(min = 2)
      group_match = @linkage_options[:group_match] || []
      ruby_types = group_match.inject({}) do |hsh, m|
        key = m[:alias] || m[:meta_object].to_expr
        hsh[key] = m[:meta_object].ruby_type
        hsh
      end
      options = {:database_type => database_type, :ruby_types => ruby_types }
      @dataset.group_and_count(*match_expressions).having{count >= min}.each do |row|
        count = row.delete(:count)
        group = Group.new(row, options.merge(:count => count))
        yield group
      end
    end

    def group_by_matches(raw = true)
      expr = raw ? raw_match_expressions : match_expressions
      group(*expr)
    end

    def dataset_for_group(group)
      filters = []
      group_match = @linkage_options[:group_match] || []
      group.values.each_pair do |key, value|
        # find a matched expression with this alias
        found = false
        group_match.each do |m|
          expr = m[:meta_object].to_expr
          if (m[:alias] && m[:alias] == key) || expr == key
            found = true
            filters << {expr => value}
            break
          end
        end
        if !found
          raise "this dataset isn't compatible with the given group"
        end
      end
      filter(*filters)
    end

    def schema
      @db.schema(@table_name)
    end

    private

    def raw_match_expressions
      group_match = @linkage_options[:group_match] || []
      group_match.collect { |m| m[:meta_object].to_expr }
    end

    def match_expressions
      group_match = @linkage_options[:group_match] || []
      group_match.collect do |m|
        expr = m[:meta_object].to_expr
        expr = expr.as(m[:alias]) if m[:alias]
        expr = expr.cast(m[:cast]) if m[:cast]
        expr
      end
    end

    def method_missing(name, *args, &block)
      result = @dataset.send(name, *args, &block)
      if result.kind_of?(Sequel::Dataset)
        new_obj = result
        result = clone(:new_obj => result)
      end
      result
    end
  end
end
