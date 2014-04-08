class Tile

  attr_reader :mark, :flagged, :revealed, :position

  def initialize(position)
    @position = position
    @bombed = false
    @flagged = false
    @revealed = false
    @mark = "*"
    @neighbors = []
  end

  def set_neighbors(board)
    first, last = @position
    positions = [
      [first - 1, last - 1],
      [first - 1, last],
      [first - 1, last + 1],
      [first, last - 1],
      [first, last + 1],
      [first + 1, last - 1],
      [first + 1, last],
      [first + 1, last + 1]
    ]

    positions.each do |pos|
      if on_board?(board, pos)
        neighbor = board[pos]
        @neighbors << neighbor unless @neighbors.include?(neighbor)
      end
    end
  end

  def on_board?(board, position)
    first, last = position
    (0...board.height).cover?(first) && (0...board.width).cover?(last)
  end

  def inspect
    "pos: #{@position}, b: #{@bombed}, f: #{@flagged}, r: #{@revealed}, neighbors: #{self.inspect_neighbors}"
  end

  def inspect_neighbors
    return "[]" if @neighbors.length == 0
    neighbor_pos = []
    @neighbors.each do |neighbor|
      neighbor_pos << neighbor.position
    end
    neighbor_pos
  end

  def set_bomb
    @bombed = true
  end

  def toggle_flag
    if @mark == "F"
      @mark = "*"
    else
      @mark = "F"
    end
    puts "flagged!"
    @flagged = !@flagged
  end

  def reveal
    @revealed = true
    # recursive reveal
  end

  def bombed?
    @bombed
  end

  def flagged?
    @flagged
  end

  def revealed?
    @revealed
  end

end

class Board
  attr_reader :bomb_count, :tiles, :height, :width
  # attr_accessor

  def initialize(height = 9, width = 9)
    @height = height
    @width = width
    @tiles = Array.new(@height) { Array.new(@width) }
    generate_tiles
    set_tile_neighbors
    # @bomb_count = self.generate_bombs
  end

  def generate_tiles
    @tiles.each_with_index do |row, i|
      row.each_index do |j|
        @tiles[i][j] = Tile.new([i,j])
      end
    end
  end

  def set_tile_neighbors
    @tiles.each_index do |row|
      @tiles.each_index do |col|
        self[[row,col]].set_neighbors(self)
      end
    end
  end

  def [](pos)
    first, last = pos
    @tiles[first][last]
  end

  def []=(pos)
  end
  # def generate_bombs
 #    total_bombs = (@height * @width * 0.15).round
 #    bomb_placements = []
 #    while bomb_placements.count < total_bombs
 #      loc = [rand(@height), rand(@width)]
 #      bomb_placements << loc unless bomb_placements.include?(loc)
 #    end
 #    set_bombs(bomb_placements)
 #    total_bombs
 #  end
  #
  # def set_bombs(placements)
  #   placements.each do |pos|
  #     @tiles[pos.first][pos.last].set_bomb
  #   end
  # end

  def display
    # system("clear")
    display_board = []
    puts "   #{(0...@width).to_a.join(" ")}"
    @tiles.each_with_index do |rows, first|
      print "%02d " % first
      rows.each_index do |last|
        print "#{@tiles[first][last].mark} "
      end
      puts
    end
    nil
  end

  # def reveal(pos)
  #   tile = @tiles[pos.first][pos.last]
  #   tile.set_revealed unless tile.flagged || tile.revealed
  #   if tile.revealed && tile.bombed?
  #     nil
  #   elsif neighbor_bomb_count(pos) == 0
  #     neighbors(pos).each do |neighbor|
  #       neighboring_tile = @tiles[neighbor.first][neighbor.last]
  #       unless neighboring_tile.revealed || neighboring_tile.flagged
  #         reveal(neighbor)
  #       end
  #     end
  #     get_symbol(pos)
  #   end
  # end

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

  def get_user_input
    puts "Enter your move (R for reveal, F for flag) and the coordinates"
    puts "For example: 'R 3,2'"
    parse_user_input(gets.chomp)
  end

  def parse_user_input(input)
    move, coords = input.split(" ")
    [move.upcase, coords.split(",").map(&:to_i)]
  end

  def update_space(move, pos)
    first, last = pos
    p @board[pos]
    @board[pos].toggle_flag if move == "F"
    # @board.reveal(pos) if move == "R"
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
end


if __FILE__ == $PROGRAM_NAME
  game = MineSweeper.new
  game.play
end