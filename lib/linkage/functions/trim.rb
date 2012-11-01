module Linkage
  module Functions
    class Trim < Function
      def self.function_name
        "trim"
      end

      def self.parameters
        [[String]]
      end

      def ruby_type
        if @args[0].kind_of?(Data)
          @args[0].ruby_type
        else
          {:type => String}
        end
      end

      def collation
        if @args[0].kind_of?(Data)
          @args[0].collation
        else
          super
        end
      end
    end
    Function.register(Trim)
  end
end
