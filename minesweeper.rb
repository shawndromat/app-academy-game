class Tile

  attr_reader :mark, :flagged, :revealed

  def initialize()
    @bomb = false
    @flagged = false
    @revealed = false
    @mark = "*"
  end

  def set_bomb
    @bomb = !@bomb
  end

  def set_flagged
    @flagged = !@flagged
  end

  def set_revealed
    @revealed = !@revealed
  end

  def set_mark(mark)
    @mark = mark
  end

  def bombed?
    @bomb
  end

end

class Board
  attr_accessor :tiles

  def initialize(height = 15, width = 9)
    @height = height
    @width = width
    @tiles = Array.new(@height) { Array.new(@width) { Tile.new } }
  end

  def generate_bombs
    total_bombs = (@height * @width * 0.15) / 1
    bomb_placements = []
    while bomb_placements.count < total_bombs
      x = rand(@width)
      y = rand(@height)
      loc = [y, x]
      bomb_placements << loc unless bomb_placements.include?(loc)
    end
    set_bombs(bomb_placements)
  end

  def set_bombs(placements)
    placements.each do |pos|
      @tiles[pos.first][pos.last].set_bomb
    end
  end

  def display
    display_board = []
    @tiles.each_with_index do |rows, pos_y|
      rows.each_index do |pos_x|
        print get_symbol([pos_y, pos_x])
      end
      puts
    end
    nil
  end

  def get_symbol(pos)
    # print pos
    tile = @tiles[pos.first][pos.last]
    return "F" if tile.flagged
    if tile.revealed
      bomb_count = neighbor_bomb_count(pos)
      if bomb_count == 0
        "_"
      else
        bomb_count.to_s
      end
    else
      "*"
    end
  end

  def neighbors(pos)
    y, x = pos
    neighbors_pos = [[y - 1, x - 1],
                     [y - 1, x],
                     [y - 1, x + 1],
                     [y, x - 1],
                     [y, x + 1],
                     [y + 1, x - 1],
                     [y + 1, x],
                     [y + 1, x + 1]
                    ]
    neighbors_pos.select { |position| on_board?(position) }
  end

  def on_board?(pos)
    (0...@width).cover?(pos.first) && (0...@height).cover?(pos.last)
  end

  def neighbor_bomb_count(pos)
    neighbors(pos).select{ |pos| @tiles[pos.first][pos.last].bombed? }.count
  end

  def reveal(pos)
    tile = @tiles[pos.first][pos.last]
    tile.set_revealed
    if tile.revealed && tile.bombed?
      nil
    else
      tile.get_symbol(pos)
    end
  end

  def flag(pos)
    @tiles[pos.first][pos.last].set_flagged
  end

end

class MineSweeper

  def initialize
    @board = Board.new
  end

  def play
    win?
  end

  def win?
    hidden_tile_count = 0
    @board.tiles.each do |rows|
      rows.each do |tile|
        hidden_tile_count += 1 unless tile.revealed
      end
    end
    hidden_tile_count == board.bomb_count
  end
end



# x = Board.new
# p x.on_board?([-1, 1])
# p x.on_board?([1,1])
#
# p x.neighbors([1,1])
# p x.neighbors([0,0])