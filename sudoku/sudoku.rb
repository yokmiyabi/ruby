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

    # sから空白を除去する
    s.gsub!(/\s/, "")

    # sのサイズが異常の場合は例外
    raise Invalid, "Grid is the wrong size" unless s.size == 81

    # 無効文字が含まれる場合は例外
    if i = s.index(/[^123456789\.]/)
      raise Invalid, "Illigal character #{s[i,1]} in puzzle"
    end

    # ASCII -> 整数配列
    s.tr!(ASCII,BIN)
    @grid = s.unpack('c*')

    # 行、列、ボックスに重複があれば例外
    raise Invalid, "Initial puzzle has duplicates" if has_duplicates?
  end

  # [Method]パズルの状態を9行（改行区切り）の文字列形式で返す
  def to_s
    (0..8).collect{|r| @grid[r*9,9].pack('c9')}.join("\n").tr(BIN,ASCII)
  end

  # [Method]Puzzleオブジェクトのコピーを返す
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

  # グリッドの1次元の添字をボックス番号に対応付けるための固定値配列
  BoxOfIndex = [
    0,0,0,1,1,1,2,2,2,0,0,0,1,1,1,2,2,2,0,0,0,1,1,1,2,2,2,
    3,3,3,4,4,4,5,5,5,3,3,3,4,4,4,5,5,5,3,3,3,4,4,4,5,5,5,
    6,6,6,7,7,7,8,8,8,6,6,6,7,7,7,8,8,8,6,6,6,7,7,7,8,8,8
  ].freeze

  # [Method]パズル用のイテレータ定義（値が未定の場合に付属ブロック呼び出し）
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

  # [Method]パズル内の行、列、ボックスの重複チェック
  def has_duplicates?
    0.upto(8) {|row| return true if rowdigits(row).uniq! }
    0.upto(8) {|col| return true if coldigits(col).uniq! }
    0.upto(8) {|box| return true if boxdigits(box).uniq! }

    false
  end

  # 数独のすべての数字の集合を格納する固定値配列
  AllDigits = [1, 2, 3, 4, 5, 6, 7, 8, 9].freeze

  #[Method]セル（row,col）に（重複を発生させずに）配置できるすべての値の配列を返す
  def possible(row, col, box)
    AllDigits - (rowdigits(row) + coldigits(col) + boxdigits(box))
  end

  # follwing methods are all private.
  private

  # [Method] 指定された行に含まれるすべての数の配列を返す
  def rowdigits(row)
    @grid[row*9,9] - [0]
  end

  # [Method] 指定された列に含まれるすべての数の配列を返す
  def coldigits(col)
    result = []
    col.step(80,9) {|i|
      v = @grid[i]
      result << v if (v != 0)
    }
    result
  end

  # ボックス番号からボックスの左上隅のセルの添字を引くための固定値配列
  BoxToIndex = [0, 3, 6, 27, 30, 33, 54, 57, 60].freeze

  # [Method] 指定されたボックスに含まれるすべての数の配列を返す
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
      when 0 #指定できる値がない、パズルが制限しすぎ
        raise Impossible
      when 1 #１種類のみみつかたのでそれをグリッドにセットする
        puzzle[row,col] = p[0]
        unchanged = false
      else #２種類以上の値がみつかった
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

