require 'colorize'
require 'io/console'

class Tile

  attr_reader :mark, :flagged, :revealed, :position

  def initialize(position)
    @position = position
    @bombed, @flagged, @revealed, @cursor = false, false, false, false
    @mark = chars[:hidden]
    @neighbors = []
  end

  def chars
    { :hidden => "\u258b".encode('utf-8'),
      :flag => "\u2691".encode('utf-8').blue,
      :revealed => "\u2581".encode('utf-8'),
      :bomb => "\u2573".encode('utf-8').red
    }
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
    @flagged = !@flagged
    if @flagged
      @mark = chars[:flag]
    else
      @mark = chars[:hidden]
    end
  end

  def reveal
    return self if flagged?
    return self if revealed?

    @revealed = true
    if bombed?
      @mark = chars[:bomb]
      return
    elsif neighbor_bomb_count == 0
      @mark = chars[:revealed]
      @neighbors.each do |neighbor|
        neighbor.reveal unless neighbor.revealed? || neighbor.flagged?
      end
    else
      @mark = neighbor_bomb_count.to_s
    end
  end

  def neighbor_bomb_count
    @neighbors.select { |neighbor| neighbor.bombed? }.count
  end

  def set_bomb
    @bombed = true
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

  def set_cursor
    @mark = @mark.blink
  end

  def unset_cursor
    @mark = @mark.uncolorize
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
    generate_bombs
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

  def generate_bombs
     total_bombs = (@height * @width * 0.15).round
     bomb_placements = []
     while bomb_placements.count < total_bombs
       pos = [rand(@height), rand(@width)]
       bomb_placements << pos unless bomb_placements.include?(pos)
     end
     set_bombs(bomb_placements)
     total_bombs
   end

   def set_bombs(placements)
     placements.each do |pos|
       @tiles[pos.first][pos.last].set_bomb
     end
   end

end

class MineSweeper

  def initialize
    @board = Board.new
    @cursor = @board[[0,0]]
    @done = false
  end

  def play
    until done?

      @cursor.set_cursor
      @board.display
      # move = get_character
#       p move
#       pos = []
#       pos[0] = get_character
#       pos[1] = get_character
#       p pos
#       # puts c
#       # move, pos = get_user_input
      #
      # @board.display
      @cursor.unset_cursor
      move = $stdin.getch
      # move, pos = get_user_input
      update_space(move, @cursor)
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
    @done = true if move.upcase == "Q"
    @cursor.toggle_flag if move.upcase == "F"
    @cursor.reveal if move.upcase == "R"

    move_cursor(:up) if move.upcase == "W"
    move_cursor(:left) if move.upcase == "A"
    move_cursor(:down) if move.upcase == "S"
    move_cursor(:right) if move.upcase == "D"
  end

  def move_cursor(direction)
    first, last = @cursor.position
    target = case direction
      when :up
        [first - 1, last]
      when :left
        [first, last - 1]
      when :down
        [first + 1, last]
      when :right
        [first, last + 1]
      end
      # @board[[first,last]].unset_cursor
      @cursor = @board[target] if @cursor.on_board?(@board, target)
  end

  def win?
    all_tiles = @board.tiles.flatten
    num_revealed = all_tiles.select{ |tile| tile.revealed? }.count
    num_not_bombed = all_tiles.select{ |tile| !tile.bombed? }.count
    num_revealed == num_not_bombed
  end

  def lose?
    all_tiles = @board.tiles.flatten
    all_tiles.any? { |tile| tile.revealed? && tile.bombed? }
  end

  def done?
    win? || lose? || @done
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
