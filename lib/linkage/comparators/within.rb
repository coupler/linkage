module Linkage
  module Comparators
    class Within < Comparator
      @@parameters = [
        [:any, :static => false, :side => :first],
        [Fixnum],
        [:any, :same_type_as => 0, :static => false, :side => :second]
      ]
      def self.parameters
        @@parameters
      end

      @@comparator_name = 'within'
      def self.comparator_name
        @@comparator_name
      end

      def initialize(*args)
        super
        @name_1 = @args[0].name
        @value = @args[1].object
        @name_2 = @args[2].name
      end

      def score(record_1, record_2)
        (record_1[@name_1] - record_2[@name_2]).abs <= @value ? 1 : 0
      end
    end

    Comparator.register(Within)
  end
end
