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
    @revealed = true
  end

  def set_mark(mark)
    @mark = mark
  end

  def bombed?
    @bomb
  end

end

class Board
  attr_reader :bomb_count
  attr_accessor :tiles

  def initialize(height = 15, width = 9)
    @height = height
    @width = width
    @tiles = Array.new(@height) { Array.new(@width) { Tile.new } }
    @bomb_count = self.generate_bombs
  end

  def generate_bombs
    total_bombs = (@height * @width * 0.15).round
    bomb_placements = []
    while bomb_placements.count < total_bombs
      loc = [rand(@height), rand(@width)]
      bomb_placements << loc unless bomb_placements.include?(loc)
    end
    set_bombs(bomb_placements)
    total_bombs
  end

  def set_bombs(placements)
    placements.each do |pos|
      @tiles[pos.first][pos.last].set_bomb
    end
  end

  def display
    display_board = []
    system("clear")
    print "   "
    (0...@width).each { |num| print "#{num} " }
    puts
    @tiles.each_with_index do |rows, first|
      print "%02d " % first
      rows.each_index do |last|
        print "#{get_symbol([first, last])} "
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
      return "B" if tile.bombed?
      if bomb_count == 0
        "_"
      else
        bomb_count.to_s
      end
    else
      # return "B" if tile.bombed?
      "*"
    end
  end

  def neighbors(pos)
    first, last = pos
    neighbors_pos = [[first - 1, last - 1],
                     [first - 1, last],
                     [first - 1, last + 1],
                     [first, last - 1],
                     [first, last + 1],
                     [first + 1, last - 1],
                     [first + 1, last],
                     [first + 1, last + 1]
                    ]
    neighbors_pos.select { |position| on_board?(position) }
  end

  def on_board?(pos)
    (0...@height).cover?(pos.first) && (0...@width).cover?(pos.last)
  end

  def neighbor_bomb_count(pos)
    neighbors(pos).select{ |pos| @tiles[pos.first][pos.last].bombed? }.count
  end

  def reveal(pos)
    tile = @tiles[pos.first][pos.last]
    tile.set_revealed unless tile.flagged || tile.revealed
    if tile.revealed && tile.bombed?
      nil
    elsif neighbor_bomb_count(pos) == 0
      neighbors(pos).each do |neighbor|
        neighboring_tile = @tiles[neighbor.first][neighbor.last]
        unless neighboring_tile.revealed || neighboring_tile.flagged
          reveal(neighbor)
        end
      end
      get_symbol(pos)
    end
  end

  def flag(pos)
    tile = @tiles[pos.first][pos.last]
    tile.set_flagged unless tile.revealed
  end

end

class MineSweeper

  def initialize
    @board = Board.new
  end

  def play
    until done?
      @board.display
      move, pos = get_user_input
      update_space(move, pos)
    end
    display_results(win?)
  end

  def display_results(winner)
    end_message = "You're a WINNER!"
    unless winner
      end_message = "You're a LOSER!"
      @board.tiles.each do |rows|
        rows.each { |tile| tile.set_revealed if tile.bombed?}
      end
    end
    @board.display
    puts end_message
  end

  def win?
    hidden_tile_count = 0
    @board.tiles.each do |rows|
      rows.each do |tile|
        hidden_tile_count += 1 unless tile.revealed
      end
    end
    hidden_tile_count == @board.bomb_count
  end

  def lose?
    @board.tiles.each do |rows|
      rows.each do |tile|
        return true if tile.bombed? and tile.revealed
      end
    end
    false
  end

  def done?
    win? || lose?
  end

  def get_user_input
    puts "Enter your move (R for reveal, F for flag) and the coordinates"
    puts "For example: 'R 3,2'"
    parse_user_input(gets.chomp)
  end

  def parse_user_input(input)
    input_array = input.split(" ")
    move = input_array.first.upcase
    coords = input_array.last.split(",").map(&:to_i)
    [move, coords]
  end

  def update_space(move, pos)
    @board.flag(pos) if move == "F"
    @board.reveal(pos) if move == "R"
  end
end


if __FILE__ == $PROGRAM_NAME
  game = MineSweeper.new
  game.play
end