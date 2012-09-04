module Linkage
  module Functions
    class Binary < Function
      def self.function_name
        "binary"
      end

      def self.parameters
        [[String]]
      end

      def ruby_type
        {:type => File}
      end

      def to_expr(options = {})
        assert_dataset
        expr =
          case dataset.database_type
          when :sqlite
            @values[0].cast(:blob)
          when :postgres
            @values[0].cast(:bytea)
          else
            @values[0].cast(:binary)
          end
      end
    end
    Function.register(Binary)
  end
end
