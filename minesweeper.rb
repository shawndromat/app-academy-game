class Tile

  attr_reader :mark, :flagged, :revealed, :position

  def initialize(position)
    @position = position
    @bombed = (true if [1,2,3,4,5,6].sample == 1) || false
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
    [].tap do |neighbor_pos|
      @neighbors.each do |neighbor|
        neighbor_pos << neighbor.position
      end
    end
  end

  def toggle_flag
    if @mark == "F"
      @mark = "*"
    else
      @mark = "F"
    end
    @flagged = !@flagged
  end

  def reveal
    return self if flagged?
    return self if revealed?

    @revealed = true
    if bombed?
      @mark = "B"
      return
    elsif neighbor_bomb_count == 0
      @mark = "_"
      @neighbors.each do |neighbor|
        neighbor.reveal unless neighbor.revealed? || neighbor.flagged?
      end
    else
      @mark = neighbor_bomb_count
    end
  end

  def neighbor_bomb_count
    @neighbors.select { |neighbor| neighbor.bombed? }.count
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

  def initialize(height = 9, width = 9)
    @height = height
    @width = width
    @tiles = Array.new(@height) { Array.new(@width) }
    generate_tiles
    set_tile_neighbors
  end

  def [](pos)
    first, last = pos
    @tiles[first][last]
  end


  def generate_tiles
    @tiles.each_with_index do |row, i|
      row.each_index do |j|
        self.tiles[i][j] = Tile.new([i,j])
      end
    end
  end

  def set_tile_neighbors
    @tiles.each_index do |i|
      @tiles.each_index do |j|
        self.tiles[i][j].set_neighbors(self)
      end
    end
  end

  def display
    system("clear")
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
    @board[pos].toggle_flag if move == "F"
    @board[pos].reveal if move == "R"
  end

  def win?
    all_tiles = @board.tiles.flatten
    all_tiles.all? { |tile| tile.revealed? && !tile.bombed? }
  end

  def lose?
    all_tiles = @board.tiles.flatten
    all_tiles.any? { |tile| tile.revealed? && tile.bombed? }
  end

  def done?
    win? || lose?
  end

  def display_results(winner)
    end_message = "You're a WINNER!"
    unless winner
      end_message = "You're a LOSER!"
      @board.tiles.each do |rows|
        rows.each { |tile| tile.reveal if tile.bombed?}
      end
    end
    @board.display
    puts end_message
  end
end


if __FILE__ == $PROGRAM_NAME
  game = MineSweeper.new
  game.play
end
