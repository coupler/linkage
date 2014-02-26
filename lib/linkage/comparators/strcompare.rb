module Linkage
  module Comparators
    # Strcompare is a string comparison comparator. It uses the specified
    # operation to compare string-type fields. Score ranges from 0 to 1.
    #
    # To use Strcompare, you must specify one field for each record to use in
    # the comparison, along with an operator. Valid operators are:
    #
    # * `:jarowinkler` ([Jaro-Winkler distance](http://en.wikipedia.org/wiki/Jaro%E2%80%93Winkler_distance))
    #
    # Consider the following example, using a {Configuration} as part of
    # {Dataset#link_with}:
    #
    # ```ruby
    # config.strcompare(:foo, :bar, :jarowinkler)
    # ```
    #
    # For each record, the values of the `foo` and `bar` fields are compared
    # using the Jaro-Winkler distance algorithm.
    class Strcompare < Comparator
      VALID_OPERATIONS = [:jarowinkler]

      def initialize(field_1, field_2, operation)
        if field_1.ruby_type[:type] != String || field_2.ruby_type[:type] != String
          raise "fields must be string types"
        end
        if !VALID_OPERATIONS.include?(operation)
          raise "#{operation.inspect} is not a valid operation"
        end

        @name_1 = field_1.name
        @name_2 = field_2.name
        @operation = operation
      end

      def score(record_1, record_2)
        result =
          case @operation
          when :jarowinkler
            jarowinkler(record_1[@name_1], record_2[@name_2])
          end

        result
      end

      def jarowinkler(w1, w2)
        a = w1.downcase
        b = w2.downcase
        aa = a.split('')
        ba = b.split('')
        al = a.length
        bl = b.length
        l = 0
        for i in Range.new(0, [[al, bl].min, 4].min-1)
          break if aa[i] != ba[i]
          l += 1
        end
        aj = aa - (aa - ba)
        bj = ba - (ba - aa)
        nm = 0
        nt = 0
        md = [[al, bl].max/2 - 1, 0].max
        for i in Range.new(0, al-1)
          bi = ba.index(aa[i])
          aji = aj.index(aa[i])
          bji = bj.index(aa[i])
          if !bi.nil? && (bi + nm - i).abs <= md
            nm += 1
            nt += 1 if !bji.nil? && aji != bji
          end
          ba.delete_at(bi) if !bi.nil?
          aj.delete_at(aji) if !aji.nil?
          bj.delete_at(bji) if !bji.nil?
        end
        return 0 if nm == 0
        d = (nm/al.to_f + nm/bl.to_f + (nm-nt)/nm.to_f)/3.0
        w = (d + l * 0.1 * (1 - d)).round(3)
        w
      end
    end

    Comparator.register('strcompare', Strcompare)
  end
end

