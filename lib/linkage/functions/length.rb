module Linkage
  module Functions
    # Returns the number of characters in a string.
    class Length < Function
      def self.function_name
        "length"
      end

      def self.parameters
        [[String]]
      end

      def ruby_type
        {:type => Fixnum}
      end

      def to_expr(options = {})
        expr =
          case dataset.database_type
          when :mysql, :postgres
            :char_length.sql_function(@values[0])
          else
            :length.sql_function(@values[0])
          end
      end
    end
    Function.register(Length)
  end
end
