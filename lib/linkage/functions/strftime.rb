module Linkage
  module Functions
    class Strftime < Function
      def self.function_name
        "strftime"
      end

      def self.parameters
        [[Date, Time, DateTime], [String]]
      end

      def ruby_type
        # TODO: string length needed
        {:type => String}
      end

      def to_expr(adapter = nil, options = {})
        expr =
          case adapter
          when :mysql, :mysql2
            :date_format.sql_function(*@values)
          when :sqlite
            :strftime.sql_function(@values[1], @values[0])
          when :postgres
            :to_char.sql_function(*@values)
          else
            :strftime.sql_function(@values[0], @values[1])
          end
        options[:binary] ? expr.cast(:binary) : expr
      end
    end
    Function.register(Strftime)
  end
end
