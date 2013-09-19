module Linkage
  module Comparators
    class Strcompare < Comparator
      @@score_range = 0..1
      def self.score_range
        @@score_range
      end

      @@parameters = [
        [String, :static => false, :side => :first],
        [String, :values => %w{jw}],
        [String, :same_type_as => 0, :static => false, :side => :second]
      ]
      def self.parameters
        @@parameters
      end

      @@comparator_name = 'strcompare'
      def self.comparator_name
        @@comparator_name
      end

      def initialize(*args)
        super
        @name_1 = @args[0].name
        @operator = @args[1].object
        @name_2 = @args[2].name
      end

      def score(record_1, record_2)
        result =
          case @operator
          when 'jw'
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

    Comparator.register(Strcompare)
  end
end

