# -*- coding: euc-jp -*-
# require 'sudoku'
# puts Sudoku.solve(Sudoku::Puzzle.new(ARGF.readlines))

module Sudoku

#
# [Class] Sudoku::Puzzle
#
class Puzzle
  # fixnums
  ASCII = ".123456789"
  BIN = "\000\001\002\003\004\005\006\007\010\011"

  # [Method] initialize
  def initialize(lines)
    if (lines.respond_to? :join)
      s = lines.join
    else
      s = lines.dup
    end

    # s������������
    s.gsub!(/\s/, "")

    # s�Υ��������۾�ξ����㳰
    raise Invalid, "Grid is the wrong size" unless s.size == 81

    # ̵��ʸ�����ޤޤ������㳰
    if i = s.index(/[^123456789\.]/)
      raise Invalid, "Illigal character #{s[i,1]} in puzzle"
    end

    # ASCII -> ��������
    s.tr!(ASCII,BIN)
    @grid = s.unpack('c*')

    # �ԡ��󡢥ܥå����˽�ʣ��������㳰
    raise Invalid, "Initial puzzle has duplicates" if has_duplicates?
  end

  # [Method]�ѥ���ξ��֤�9�ԡʲ��Զ��ڤ�ˤ�ʸ����������֤�
  def to_s
    (0..8).collect{|r| @grid[r*9,9].pack('c9')}.join("\n").tr(BIN,ASCII)
  end

  # [Method]Puzzle���֥������ȤΥ��ԡ����֤�
  def dup
    copy = super
    @grid = @grid.dup
    copy
  end

  # override -> []
  def [](row, col)
    @grid[row*9 + col]
  end

  # override -> []=
  def []=(row, col, newvalue)
    unless (0..9).include? newvalue
      raise Invalid, "illegal cell value"
    end
    @grid[row*9 + col] = newvalue
  end

  # ����åɤ�1������ź����ܥå����ֹ���б��դ��뤿��θ���������
  BoxOfIndex = [
    0,0,0,1,1,1,2,2,2,0,0,0,1,1,1,2,2,2,0,0,0,1,1,1,2,2,2,
    3,3,3,4,4,4,5,5,5,3,3,3,4,4,4,5,5,5,3,3,3,4,4,4,5,5,5,
    6,6,6,7,7,7,8,8,8,6,6,6,7,7,7,8,8,8,6,6,6,7,7,7,8,8,8
  ].freeze

  # [Method]�ѥ����ѤΥ��ƥ졼��������ͤ�̤��ξ�����°�֥�å��ƤӽФ���
  def each_unknown
    0.upto 8 do |row|
      0.upto 8 do |col|
        index = row*9+col
        next if @grid[index] != 0
        box = BoxOfIndex[index]
        yield row, col, box
      end
    end
  end

  # [Method]�ѥ�����ιԡ��󡢥ܥå����ν�ʣ�����å�
  def has_duplicates?
    0.upto(8) {|row| return true if rowdigits(row).uniq! }
    0.upto(8) {|col| return true if coldigits(col).uniq! }
    0.upto(8) {|box| return true if boxdigits(box).uniq! }

    false
  end

  # ���ȤΤ��٤Ƥο����ν�����Ǽ�������������
  AllDigits = [1, 2, 3, 4, 5, 6, 7, 8, 9].freeze

  #[Method]�����row,col�ˤˡʽ�ʣ��ȯ���������ˡ����֤Ǥ��뤹�٤Ƥ��ͤ�������֤�
  def possible(row, col, box)
    AllDigits - (rowdigits(row) + coldigits(col) + boxdigits(box))
  end

  # follwing methods are all private.
  private

  # [Method] ���ꤵ�줿�Ԥ˴ޤޤ�뤹�٤Ƥο���������֤�
  def rowdigits(row)
    @grid[row*9,9] - [0]
  end

  # [Method] ���ꤵ�줿��˴ޤޤ�뤹�٤Ƥο���������֤�
  def coldigits(col)
    result = []
    col.step(80,9) {|i|
      v = @grid[i]
      result << v if (v != 0)
    }
    result
  end

  # �ܥå����ֹ椫��ܥå����κ�����Υ����ź�����������θ���������
  BoxToIndex = [0, 3, 6, 27, 30, 33, 54, 57, 60].freeze

  # [Method] ���ꤵ�줿�ܥå����˴ޤޤ�뤹�٤Ƥο���������֤�
  def boxdigits(b)
    i = BoxToIndex[b]
    [
     @grid[i],    @grid[i+1],  @grid[i+2],
     @grid[i+9],  @grid[i+10], @grid[i+11],
     @grid[i+18], @grid[i+19], @grid[i+20]
    ] - [0]
  end
end # end of Class(Puzzle)

class Invalid < StandardError
end

class Impossible < StandardError
end

def Sudoku.scan(puzzle)
  unchanged = false

  until unchanged
    unchanged = true
    rmin,cmin,pmin = nil
    min = 10

    puzzle.each_unknown do |row, col, box|
      p = puzzle.possible(row, col, box)

      case p.size
      when 0 #����Ǥ����ͤ��ʤ����ѥ��뤬���¤�����
        raise Impossible
      when 1 #������ΤߤߤĤ����ΤǤ���򥰥�åɤ˥��åȤ���
        puzzle[row,col] = p[0]
        unchanged = false
      else #������ʾ���ͤ��ߤĤ��ä�
        if unchanged && p.size < min
          min = p.size
          rmin, cmin, pmin = row, col, p
        end
      end
    end
  end
  return rmin, cmin, pmin
end

def Sudoku.solve(puzzle)
  puzzle = puzzle.dup

  r,c,p = scan(puzzle)

  return puzzle if r == nil

  p.each do |guess|
    puzzle[r,c] = guess

    begin
      return solve(puzzle)
    resucue Impossible
      next
    end
  end
  raise Impossible
end

end

