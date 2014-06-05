module Linkage
  module Comparators
    # Strcompare is a string comparison comparator. It uses the specified
    # operation to compare string-type fields. Score ranges from 0 to 1.
    #
    # To use Strcompare, you must specify one field for each record to use in
    # the comparison, along with an operator. Valid operators are:
    #
    # * `:jarowinkler` ([Jaro-Winkler distance](http://en.wikipedia.org/wiki/Jaro%E2%80%93Winkler_distance))
    # * `:damerau_levenshtein` ([Damerau-Levenshtein distance](http://en.wikipedia.org/wiki/Damerau%E2%80%93Levenshtein_distance))
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
    #
    # Damerau-Levenshtein is a modified Levenshtein that allows for transpositions
    # It has additionally been modified to make costs of additions or deletions only 0.5
    class Strcompare < Comparator
      VALID_OPERATIONS = [:jarowinkler, :damerau_levenshtein]

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
          when :damerau_levenshtein
            damerau_levenshtein(record_1[@name_1], record_2[@name_2])
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
        md = [[al, bl].max/2 - 1, 0].max
        bada = []
        badb = []
        # simplify to matching characters
        for i in Range.new(0, al-1)
          fi = [i - md, 0].max
          li = [i + md, bl].min
          bada << i if ba[fi, li-fi].index(aa[i]).nil?
        end
        for i in Range.new(0, bl-1)
          fi = [i - md, 0].max
          li = [i + md, al].min
          badb << i if aa[fi, li-fi].index(ba[i]).nil?
        end
        bada.reverse.each { |x| aa.delete_at(x) }
        badb.reverse.each { |x| ba.delete_at(x) }
        nm = aa.length
        return 0 if nm == 0
        nt = 0
        for i in Range.new(0, nm-1)
          nt +=1 if aa[i] != ba[i]
        end
        d = (nm/al.to_f + nm/bl.to_f + (nm-nt/2)/nm.to_f)/3.0
        w = (d + l * 0.1 * (1 - d)).round(3)
        w
      end

      def damerau_levenshtein(w1, w2)
        a = w1.downcase
        b = w2.downcase
        aa = a.split('')
        ba = b.split('')
        al = a.length
        bl = b.length
        denom = [al, bl].max
        return 0 if denom == 0
        oneago = nil
        thisrow = (1..bl).to_a + [0]
        al.times do |x|
          twoago, oneago, thisrow = oneago, thisrow, [0] * bl + [x + 1]
          bl.times do |y|
            if aa[x] == ba[y]
              thisrow[y] = oneago[y - 1]
            else
              delcost = oneago[y] + 0.5
              addcost = thisrow[y - 1] + 0.5
              subcost = oneago[y - 1] + 1
              thisrow[y] = [delcost, addcost, subcost].min
              # remove this statement for original levenshtein
              if x > 0 and y > 0 and aa[x] == ba[y-1] and aa[x-1] == ba[y]
                thisrow[y] = [thisrow[y], twoago[y-2] + 1].min
              end
            end
          end
        end
        return (1 - thisrow[bl - 1] / denom.to_f).round(3)
      end
    end

    Comparator.register('strcompare', Strcompare)
  end
end

