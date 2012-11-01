module Linkage
  module Functions
    class Cast < Function
      def self.function_name
        "cast"
      end

      def self.parameters
        [[:any], [String]]
      end

      def ruby_type
        type =
          case @values[1]
          when 'integer'
            Fixnum
          when 'binary'
            File
          else
            raise "unknown type: #{@values[1]}"
          end

        {:type => type}
      end

      def to_expr(options = {})
        cast =
          case @values[1]
          when 'integer'
            case dataset.database_type
            when :sqlite, :postgres, :h2
              :integer
            when :mysql
              :signed
            end
          when 'binary'
            case dataset.database_type
            when :sqlite
              :blob
            when :postgres
              :bytea
            when :mysql, :h2
              :binary
            end
          end

        if cast
          @values[0].cast(cast)
        end
      end
    end
    Function.register(Cast)
  end
end
