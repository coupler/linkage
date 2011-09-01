module Linkage
  # This class is for holding information about a particular field in a
  # dataset.
  class Field
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

    # @return [Symbol] This field's name
    attr_reader :name

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
        @ruby_type =
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
        @ruby_type.delete_if { |k, v| v.nil? }
      end
      @ruby_type
    end

    # Create a field that can hold data from two other fields. If the fields
    # have different types, the resulting type is determined via a
    # type-conversion tree.
    #
    # @param [Linkage::Field] other
    # @return [Linkage::Field]
    def merge(other)
      schema_1 = self.ruby_type
      schema_2 = other.ruby_type
      if schema_1 == schema_2
        result = schema_1
      else
        result = schema_1.dup

        # type
        if schema_1[:type] != schema_2[:type]
          result[:type] = first_common_type(schema_1[:type], schema_2[:type])
        end

        # text
        if schema_1[:text] != schema_2[:text]
          # This can only be of type String.
          result[:text] = true
          result.delete(:size)
        end

        # size
        if !result[:text] && schema_1[:size] != schema_2[:size]
          types = [schema_1[:type], schema_2[:type]].uniq
          if types.length == 1 && types[0] == BigDecimal
            # Two decimals
            if schema_1.has_key?(:size) && schema_2.has_key?(:size)
              s_1 = schema_1[:size]
              s_2 = schema_2[:size]
              result[:size] = [ s_1[0] > s_2[0] ? s_1[0] : s_2[0] ]

              if s_1[1] && s_2[1]
                result[:size][1] = s_1[1] > s_2[1] ? s_1[1] : s_2[1]
              else
                result[:size][1] = s_1[1] ? s_1[1] : s_2[1]
              end
            else
              result[:size] = schema_1.has_key?(:size) ? schema_1[:size] : schema_2[:size]
            end
          elsif types.include?(String) && types.include?(BigDecimal)
            # Add one to the precision of the BigDecimal (for the dot)
            if schema_1.has_key?(:size) && schema_2.has_key?(:size)
              s_1 = schema_1[:size].is_a?(Array) ? schema_1[:size][0] + 1 : schema_1[:size]
              s_2 = schema_2[:size].is_a?(Array) ? schema_2[:size][0] + 1 : schema_2[:size]
              result[:size] = s_1 > s_2 ? s_1 : s_2
            elsif schema_1.has_key?(:size)
              result[:size] = schema_1[:size].is_a?(Array) ? schema_1[:size][0] + 1 : schema_1[:size]
            elsif schema_2.has_key?(:size)
              result[:size] = schema_2[:size].is_a?(Array) ? schema_2[:size][0] + 1 : schema_2[:size]
            end
          else
            # Treat as two strings
            if schema_1.has_key?(:size) && schema_2.has_key?(:size)
              result[:size] = schema_1[:size] > schema_2[:size] ? schema_1[:size] : schema_2[:size]
            elsif schema_1.has_key?(:size)
              result[:size] = schema_1[:size]
            else
              result[:size] = schema_2[:size]
            end
          end
        end

        # fixed
        if schema_1[:fixed] != schema_2[:fixed]
          # This can only be of type String.
          result[:fixed] = true
        end
      end

      name = self.name == other.name ? self.name : :"#{self.name}_#{other.name}"
      Field.new(name, nil, result)
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
