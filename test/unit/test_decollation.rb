# encoding: utf-8
require 'helper'

class UnitTests::TestDecollation < Test::Unit::TestCase
  include Linkage::Decollation

  test "mysql's latin1_swedish_ci handles 'A' letters" do
    # MySQL 6.0.4 collation (http://www.collation-charts.org/mysql60/mysql604.latin1_swedish_ci.html)
    ["A", "a", "À", "Á", "Â", "Ã", "à", "á", "â", "ã"].each do |chr|
      assert_equal "A", decollate(chr, :mysql, :latin1_swedish_ci)
    end
  end

  test "mysql's latin1_swedish_ci handles 'B' letters" do
    ["B", "b"].each do |chr|
      assert_equal "B", decollate(chr, :mysql, :latin1_swedish_ci)
    end
  end

  test "mysql's latin1_swedish_ci handles 'C' letters" do
    ["C", "c", "Ç", "ç"].each do |chr|
      assert_equal "C", decollate(chr, :mysql, :latin1_swedish_ci)
    end
  end

  test "mysql's latin1_swedish_ci handles 'D' letters" do
    ["D", "d", "Ð", "ð"].each do |chr|
      assert_equal "D", decollate(chr, :mysql, :latin1_swedish_ci)
    end
  end

  test "mysql's latin1_swedish_ci handles 'E' letters" do
    ["E", "e", "È", "É", "Ê", "Ë", "è", "é", "ê", "ë"].each do |chr|
      assert_equal "E", decollate(chr, :mysql, :latin1_swedish_ci)
    end
  end

  test "mysql's latin1_swedish_ci handles 'F' letters" do
    ["F", "f"].each do |chr|
      assert_equal "F", decollate(chr, :mysql, :latin1_swedish_ci)
    end
  end

  test "mysql's latin1_swedish_ci handles 'G' letters" do
    ["G", "g"].each do |chr|
      assert_equal "G", decollate(chr, :mysql, :latin1_swedish_ci)
    end
  end

  test "mysql's latin1_swedish_ci handles 'H' letters" do
    ["H", "h"].each do |chr|
      assert_equal "H", decollate(chr, :mysql, :latin1_swedish_ci)
    end
  end

  test "mysql's latin1_swedish_ci handles 'I' letters" do
    ["I", "i", "Ì", "Í", "Î", "Ï", "ì", "í", "î", "ï"].each do |chr|
      assert_equal "I", decollate(chr, :mysql, :latin1_swedish_ci)
    end
  end

  test "mysql's latin1_swedish_ci handles 'J' letters" do
    ["J", "j"].each do |chr|
      assert_equal "J", decollate(chr, :mysql, :latin1_swedish_ci)
    end
  end

  test "mysql's latin1_swedish_ci handles 'K' letters" do
    ["K", "k"].each do |chr|
      assert_equal "K", decollate(chr, :mysql, :latin1_swedish_ci)
    end
  end

  test "mysql's latin1_swedish_ci handles 'L' letters" do
    ["L", "l"].each do |chr|
      assert_equal "L", decollate(chr, :mysql, :latin1_swedish_ci)
    end
  end

  test "mysql's latin1_swedish_ci handles 'M' letters" do
    ["M", "m"].each do |chr|
      assert_equal "M", decollate(chr, :mysql, :latin1_swedish_ci)
    end
  end

  test "mysql's latin1_swedish_ci handles 'N' letters" do
    ["N", "n", "Ñ", "ñ"].each do |chr|
      assert_equal "N", decollate(chr, :mysql, :latin1_swedish_ci)
    end
  end

  test "mysql's latin1_swedish_ci handles 'O' letters" do
    ["O", "o", "Ò", "Ó", "Ô", "Õ", "ò", "ó", "ô", "õ"].each do |chr|
      assert_equal "O", decollate(chr, :mysql, :latin1_swedish_ci)
    end
  end

  test "mysql's latin1_swedish_ci handles 'P' letters" do
    ["P", "p"].each do |chr|
      assert_equal "P", decollate(chr, :mysql, :latin1_swedish_ci)
    end
  end

  test "mysql's latin1_swedish_ci handles 'Q' letters" do
    ["Q", "q"].each do |chr|
      assert_equal "Q", decollate(chr, :mysql, :latin1_swedish_ci)
    end
  end

  test "mysql's latin1_swedish_ci handles 'R' letters" do
    ["R", "r"].each do |chr|
      assert_equal "R", decollate(chr, :mysql, :latin1_swedish_ci)
    end
  end

  test "mysql's latin1_swedish_ci handles 'S' letters" do
    ["S", "s"].each do |chr|
      assert_equal "S", decollate(chr, :mysql, :latin1_swedish_ci)
    end
  end

  test "mysql's latin1_swedish_ci handles 'T' letters" do
    ["T", "t"].each do |chr|
      assert_equal "T", decollate(chr, :mysql, :latin1_swedish_ci)
    end
  end

  test "mysql's latin1_swedish_ci handles 'U' letters" do
    ["U", "u", "Ù", "Ú", "Û", "ù", "ú", "û"].each do |chr|
      assert_equal "U", decollate(chr, :mysql, :latin1_swedish_ci)
    end
  end

  test "mysql's latin1_swedish_ci handles 'V' letters" do
    ["V", "v"].each do |chr|
      assert_equal "V", decollate(chr, :mysql, :latin1_swedish_ci)
    end
  end

  test "mysql's latin1_swedish_ci handles 'W' letters" do
    ["W", "w"].each do |chr|
      assert_equal "W", decollate(chr, :mysql, :latin1_swedish_ci)
    end
  end

  test "mysql's latin1_swedish_ci handles 'X' letters" do
    ["X", "x"].each do |chr|
      assert_equal "X", decollate(chr, :mysql, :latin1_swedish_ci)
    end
  end

  test "mysql's latin1_swedish_ci handles 'Y' letters" do
    ["Y", "y", "Ü", "Ý", "ü", "ý"].each do |chr|
      assert_equal "Y", decollate(chr, :mysql, :latin1_swedish_ci)
    end
  end

  test "mysql's latin1_swedish_ci handles 'Z' letters" do
    ["Z", "z"].each do |chr|
      assert_equal "Z", decollate(chr, :mysql, :latin1_swedish_ci)
    end
  end

  test "mysql's latin1_swedish_ci handles '[' letters" do
    ["[", "Å", "å"].each do |chr|
      assert_equal "[", decollate(chr, :mysql, :latin1_swedish_ci)
    end
  end

  test "mysql's latin1_swedish_ci handles '\\' letters" do
    ["\\", "Ä", "Æ", "ä", "æ"].each do |chr|
      assert_equal "\\", decollate(chr, :mysql, :latin1_swedish_ci)
    end
  end

  test "mysql's latin1_swedish_ci handles ']' letters" do
    ["]", "Ö", "ö"].each do |chr|
      assert_equal "]", decollate(chr, :mysql, :latin1_swedish_ci)
    end
  end

  test "mysql's latin1_swedish_ci handles 'Ø' letters" do
    ["Ø", "ø"].each do |chr|
      assert_equal "Ø", decollate(chr, :mysql, :latin1_swedish_ci)
    end
  end

  test "mysql's latin1_swedish_ci handles 'Þ' letters" do
    ["Þ", "þ"].each do |chr|
      assert_equal "Þ", decollate(chr, :mysql, :latin1_swedish_ci)
    end
  end

  test "mysql's latin1_swedish_ci ignores trailing spaces" do
    assert_equal "FOO", decollate("foo ", :mysql, :latin1_swedish_ci)
  end

  test "unknown collation" do
    assert_equal "fOo", decollate("fOo", :foo, :bar)
  end
end
