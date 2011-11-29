module Linkage
  # This class is for holding information about a particular field in a
  # dataset.
  class Field < Data
    # A "tree" used to find compatible types.
    TYPE_CONVERSION_TREE = {
      TrueClass => [Integer],
      Integer => [Bignum, Float],
      Bignum => [BigDecimal],
      Float => [BigDecimal],
      BigDecimal => [String],
      String => nil,
      DateTime => nil,
      Date => nil,
      Time => nil,
      File => nil
    }

    # @return [Symbol] This field's schema information
    attr_reader :schema

    # @attr [Linkage::Dataset] This field's associated dataset
    attr_accessor :dataset

    # Create a new instance of Field.
    #
    # @param [Symbol] name The field's name
    # @param [Hash] schema The field's schema information
    # @param [Hash] ruby_type The field's ruby type
    def initialize(name, schema, ruby_type = nil)
      @name = name
      @schema = schema
      @ruby_type = ruby_type
    end

    # Convert the column schema information to a hash of column options, one of
    # which must be :type. The other options added should modify that type
    # (e.g. :size). If a database type is not recognized, return it as a String
    # type.
    #
    # @note This method comes more or less straight from Sequel
    #   (lib/sequel/extensions/schema_dumper.rb).
    def ruby_type
      unless @ruby_type
        hsh =
          case t = @schema[:db_type].downcase
          when /\A(?:medium|small)?int(?:eger)?(?:\((?:\d+)\))?(?: unsigned)?\z/o
            {:type=>Integer}
          when /\Atinyint(?:\((\d+)\))?\z/o
            {:type =>@schema[:type] == :boolean ? TrueClass : Integer}
          when /\Abigint(?:\((?:\d+)\))?(?: unsigned)?\z/o
            {:type=>Bignum}
          when /\A(?:real|float|double(?: precision)?)\z/o
            {:type=>Float}
          when 'boolean'
            {:type=>TrueClass}
          when /\A(?:(?:tiny|medium|long|n)?text|clob)\z/o
            {:type=>String, :text=>true}
          when 'date'
            {:type=>Date}
          when /\A(?:small)?datetime\z/o
            {:type=>DateTime}
          when /\Atimestamp(?:\((\d+)\))?(?: with(?:out)? time zone)?\z/o
            {:type=>DateTime, :size=>($1.to_i if $1)}
          when /\Atime(?: with(?:out)? time zone)?\z/o
            {:type=>Time, :only_time=>true}
          when /\An?char(?:acter)?(?:\((\d+)\))?\z/o
            {:type=>String, :size=>($1.to_i if $1), :fixed=>true}
          when /\A(?:n?varchar|character varying|bpchar|string)(?:\((\d+)\))?\z/o
            {:type=>String, :size=>($1.to_i if $1)}
          when /\A(?:small)?money\z/o
            {:type=>BigDecimal, :size=>[19,2]}
          when /\A(?:decimal|numeric|number)(?:\((\d+)(?:,\s*(\d+))?\))?\z/o
            s = [($1.to_i if $1), ($2.to_i if $2)].compact
            {:type=>BigDecimal, :size=>(s.empty? ? nil : s)}
          when /\A(?:bytea|(?:tiny|medium|long)?blob|(?:var)?binary)(?:\((\d+)\))?\z/o
            {:type=>File, :size=>($1.to_i if $1)}
          when 'year'
            {:type=>Integer}
          else
            {:type=>String}
          end
        hsh.delete_if { |k, v| v.nil? }
        @ruby_type = {:type => hsh.delete(:type)}
        @ruby_type[:opts] = hsh if !hsh.empty?
      end
      @ruby_type
    end

    def static?
      false
    end

    # Create a field that can hold data from two other fields. If the fields
    # have different types, the resulting type is determined via a
    # type-conversion tree.
    #
    # @param [Linkage::Field] other
    # @return [Linkage::Field]
    def merge(other, new_name = nil)
      schema_1 = self.ruby_type
      schema_2 = other.ruby_type
      if schema_1 == schema_2
        result = schema_1
      else
        type_1 = schema_1[:type]
        opts_1 = schema_1[:opts] || {}
        type_2 = schema_2[:type]
        opts_2 = schema_2[:opts] || {}
        result_type = type_1
        result_opts = schema_1[:opts] ? schema_1[:opts].dup : {}

        # type
        if type_1 != type_2
          result_type = first_common_type(type_1, type_2)
        end

        # text
        if opts_1[:text] != opts_2[:text]
          # This can only be of type String.
          result_opts[:text] = true
          result_opts.delete(:size)
        end

        # size
        if !result_opts[:text] && opts_1[:size] != opts_2[:size]
          types = [type_1, type_2].uniq
          if types.length == 1 && types[0] == BigDecimal
            # Two decimals
            if opts_1.has_key?(:size) && opts_2.has_key?(:size)
              s_1 = opts_1[:size]
              s_2 = opts_2[:size]
              result_opts[:size] = [ s_1[0] > s_2[0] ? s_1[0] : s_2[0] ]

              if s_1[1] && s_2[1]
                result_opts[:size][1] = s_1[1] > s_2[1] ? s_1[1] : s_2[1]
              else
                result_opts[:size][1] = s_1[1] ? s_1[1] : s_2[1]
              end
            else
              result_opts[:size] = opts_1.has_key?(:size) ? opts_1[:size] : opts_2[:size]
            end
          elsif types.include?(String) && types.include?(BigDecimal)
            # Add one to the precision of the BigDecimal (for the dot)
            if opts_1.has_key?(:size) && opts_2.has_key?(:size)
              s_1 = opts_1[:size].is_a?(Array) ? opts_1[:size][0] + 1 : opts_1[:size]
              s_2 = opts_2[:size].is_a?(Array) ? opts_2[:size][0] + 1 : opts_2[:size]
              result_opts[:size] = s_1 > s_2 ? s_1 : s_2
            elsif opts_1.has_key?(:size)
              result_opts[:size] = opts_1[:size].is_a?(Array) ? opts_1[:size][0] + 1 : opts_1[:size]
            elsif opts_2.has_key?(:size)
              result_opts[:size] = opts_2[:size].is_a?(Array) ? opts_2[:size][0] + 1 : opts_2[:size]
            end
          else
            # Treat as two strings
            if opts_1.has_key?(:size) && opts_2.has_key?(:size)
              result_opts[:size] = opts_1[:size] > opts_2[:size] ? opts_1[:size] : opts_2[:size]
            elsif opts_1.has_key?(:size)
              result_opts[:size] = opts_1[:size]
            else
              result_opts[:size] = opts_2[:size]
            end
          end
        end

        # fixed
        if opts_1[:fixed] != opts_2[:fixed]
          # This can only be of type String.
          result_opts[:fixed] = true
        end

        result = {:type => result_type}
        result[:opts] = result_opts  unless result_opts.empty?
      end

      if new_name
        name = new_name.to_sym
      else
        name = self.name == other.name ? self.name : :"#{self.name}_#{other.name}"
      end
      Field.new(name, nil, result)
    end

    # Returns true if this field's name and dataset match the other's name
    # and dataset (using {Dataset#==})
    def ==(other)
      if !other.is_a?(Field)
        super
      else
        self.name == other.name && self.dataset == other.dataset
      end
    end

    # Returns true if this field's dataset is equal to the given dataset
    # (using Dataset#id).
    #
    # @param [Linkage::Dataset]
    def belongs_to?(dataset)
      self.dataset.id == dataset.id
    end

    def primary_key?
      schema && schema[:primary_key]
    end

    private

    def first_common_type(type_1, type_2)
      types_1 = [type_1] + get_types(type_1)
      types_2 = [type_2] + get_types(type_2)
      (types_1 & types_2).first
    end

    # Get all types that the specified type can be converted to. Order
    # matters.
    def get_types(type)
      result = []
      types = TYPE_CONVERSION_TREE[type]
      if types
        result += types
        types.each do |t|
          result |= get_types(t)
        end
      end
      result
    end
  end
end
