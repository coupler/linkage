module Linkage
  module Comparators
    class Within < Comparator
      @@parameters = [[Fixnum], [Fixnum], [Fixnum]]
      def self.parameters
        @@parameters
      end

      def initialize(*args)
        super
        @name_1 = @args[0].name
        @value = @args[1].object
        @name_2 = @args[2].name
      end

      def score(record_1, record_2)
        if (record_1[@name_1] - record_2[@name_2]).abs <= @value
          100
        else
          0
        end
      end
    end
  end
end
