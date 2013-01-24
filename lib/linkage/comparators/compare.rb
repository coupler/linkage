module Linkage
  module Comparators
    class Compare < Binary
      @@parameters = [
        [:any, :static => false, :side => :first],
        [String, :values => %w{> >= <= < !=}],
        [:any, :same_type_as => 0, :static => false, :side => :second]
      ]
      def self.parameters
        @@parameters
      end

      @@comparator_name = 'compare'
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
          when '!='
            record_1[@name_1] != record_2[@name_2]
          when '>'
            record_1[@name_1] > record_2[@name_2]
          when '>='
            record_1[@name_1] >= record_2[@name_2]
          when '<='
            record_1[@name_1] <= record_2[@name_2]
          when '<'
            record_1[@name_1] < record_2[@name_2]
          end

        result ? 1 : 0
      end
    end

    Comparator.register(Compare)
  end
end
