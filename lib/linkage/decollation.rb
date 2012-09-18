# encoding: utf-8
module Linkage
  module Decollation
    def decollate(string, adapter, collation)
      case adapter
      when :mysql
        decollate_mysql(string, collation)
      end
    end

    def decollate_mysql(string, collation)
      case collation
      when :latin1_swedish_ci
        decollate_mysql_latin1_swedish_ci(string)
      end
    end

    def decollate_mysql_latin1_swedish_ci(string)
      result = string.strip
      result.each_char.with_index do |char, i|
        case char
        when 'A', 'a', 'À', 'Á', 'Â', 'Ã', 'à', 'á', 'â', 'ã'
          result[i] = 'A'
        when 'B', 'b'
          result[i] = 'B'
        when 'C', 'c', 'Ç', 'ç'
          result[i] = 'C'
        when 'D', 'd', 'Ð', 'ð'
          result[i] = 'D'
        when 'E', 'e', 'È', 'É', 'Ê', 'Ë', 'è', 'é', 'ê', 'ë'
          result[i] = 'E'
        when 'F', 'f'
          result[i] = 'F'
        when 'G', 'g'
          result[i] = 'G'
        when 'H', 'h'
          result[i] = 'H'
        when 'I', 'i', 'Ì', 'Í', 'Î', 'Ï', 'ì', 'í', 'î', 'ï'
          result[i] = 'I'
        when 'J', 'j'
          result[i] = 'J'
        when 'K', 'k'
          result[i] = 'K'
        when 'L', 'l'
          result[i] = 'L'
        when 'M', 'm'
          result[i] = 'M'
        when 'N', 'n', 'Ñ', 'ñ'
          result[i] = 'N'
        when 'O', 'o', 'Ò', 'Ó', 'Ô', 'Õ', 'ò', 'ó', 'ô', 'õ'
          result[i] = 'O'
        when 'P', 'p'
          result[i] = 'P'
        when 'Q', 'q'
          result[i] = 'Q'
        when 'R', 'r'
          result[i] = 'R'
        when 'S', 's'
          result[i] = 'S'
        when 'T', 't'
          result[i] = 'T'
        when 'U', 'u', 'Ù', 'Ú', 'Û', 'ù', 'ú', 'û'
          result[i] = 'U'
        when 'V', 'v'
          result[i] = 'V'
        when 'W', 'w'
          result[i] = 'W'
        when 'X', 'x'
          result[i] = 'X'
        when 'Y', 'y', 'Ü', 'Ý', 'ü', 'ý'
          result[i] = 'Y'
        when 'Z', 'z'
          result[i] = 'Z'
        when '[', 'Å', 'å'
          result[i] = '['
        when '\\', 'Ä', 'Æ', 'ä', 'æ'
          result[i] = '\\'
        when ']', 'Ö', 'ö'
          result[i] = ']'
        when 'Ø', 'ø'
          result[i] = 'Ø'
        when 'Þ', 'þ'
          result[i] = 'Þ'
        end
      end
      result
    end
  end
end
