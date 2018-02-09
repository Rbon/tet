require 'curses'

class Main
  def initialize
    renderer = Renderer.new
    input = Input.new(source: renderer)
    @game = Game.new(renderer: renderer, input: input)
  end

  def run
    @game.run
  end
end

class Game
  def initialize(opts)
    @play_field = Array.new(20) { Array.new(10) { [0, false] } }
    @renderer = opts[:renderer]
    @input = opts[:input]
    @running = true
    @g_num = 0
    @block_list = [IBlock, OBlock, ZBlock]
  end

  def run
    begin
      @renderer.start
      @current_block = new_block
      @current_block.spawn
      @renderer.draw(@play_field)
      while @running
        if @current_block.at_rest?
          @current_block = new_block
          @current_block.spawn
        end
        key = @input.manage
        act(key)
        apply_gravity
        @renderer.draw(@play_field)
        sleep(1/60)
      end
    ensure
      @renderer.stop
    end
  end

  def new_block
    @block_list.sample.new(play_field: @play_field)
  end

  def apply_gravity
    @g_num += 1
    if @g_num == 75
      @current_block.move_down
      @g_num = 0
    end
  end

  def act(input)
    send(input) unless input == nil
  end

  def move_left
    @current_block.move_left
  end

  def move_right
    @current_block.move_right
  end

  def move_down
    @current_block.move_down
  end

  def stop
    @running = false
  end
end

class Block
  attr_reader :data
  attr_accessor :pos

  def initialize(opts)
    @play_field = opts[:play_field]
    @data = [5, 5]
    @rest = false
  end

  def oob?
    @data.each do |cell|
     return true if cell[1][1] + @pos[1] < 0
     return true if cell[1][1] + @pos[1] > 9
     return true if cell[1][0] + @pos[0] > 19
    end
    return false
  end

  def at_rest?
    @rest
  end

  def check_collision(direction)

  end

  def move_left
    update_grid(override: 0)
    @pos[1] -= 1
    @pos[1] += 1 if oob?
    update_grid
  end

  def move_right
    update_grid(override: 0)
    @pos[1] += 1
    @pos[1] -= 1 if oob?
    # check_collision(:right)
    update_grid
  end

  def move_down
    @data.each do |cell|
      y_pos = cell[0][0] + 1
      x_pos = cell[0][1]
      if @play_field[y_pos][x_pos][1]
        update_grid(at_rest: true)
        @rest = true
      end
    end
    update_grid(override: 0)
    @pos[0] += 1
    if oob?
      @pos[0] -= 1
      @rest = true
    end
    update_grid
  end

  def update_grid(override: nil, at_rest: false)
    @data.each do |cell|
      y_pos = cell[1][0] + @pos[0]
      x_pos = cell[1][1] + @pos[1]
      @play_field[y_pos][x_pos] = override || [cell[0], at_rest]
    end
  end

  def spawn
    update_grid
  end
end

class IBlock < Block
  def initialize(opts)
    super
    @data = [
      [1, [0, 0]],
      [1, [1, 0]],
      [1, [2, 0]],
      [1, [3, 0]]
    ]
    @pos = [5, 5]
  end
end

# class LBlock < Block
  # def initialize(opts)
    # super
    # @data = [
      # [2, [0, 0]],
      # [2, [1, 0]],
      # [2, [2, 0]], [2, [2, 1]]
    # ]
  # end
# end

class OBlock < Block
  def initialize(opts)
    super
    @data = [
      [3, [0, 0]], [3, [0, 1]],
      [3, [1, 0]], [3, [1, 1]]
    ]
    @pos = [5, 5]
  end
end

class ZBlock < Block
  def initialize(opts)
    super
    @data = [
      [7, [0, 0]], [7, [0, 1]], [0, [0, 2]],
      [0, [1, 0]], [7, [1, 1]], [7, [1, 2]]
    ]
    @pos = [5, 5]
  end
end

class Input
  def initialize(opts)
    @source = opts[:source]
    @map = {
      move_left: "h",
      move_right: "l",
      move_down: "j",
      stop: "q"
    }.invert
  end

  def manage
    @map[@source.input]
  end
end

class Renderer
  def start
    Curses.init_screen
    Curses.curs_set(0) # Invisible cursor
    Curses.noecho # Don't display pressed characters
    @window = Curses::Window.new(42, 22, 0, 0)
    @window.box("|", "-")
    @window.keypad = true
    @window.timeout = 10
    @map = ["  ", "II", "LL", "OO", "JJ", "SS", "TT", "ZZ"]
    @dev_window = Curses::Window.new(30, 30, 0, 30)
    @dev_window.setpos(1, 1)
  end

  def stop
    Curses.close_screen
  end

  def draw(grid)
    y_pos = 0
    @window.setpos(0, 1)
    grid.each do |row|
      2.times do
        y_pos += 1
        @window.setpos(y_pos, 1)
        row.each do |cell|
          @window.addstr(@map[cell[0]])
        end
      end
    end
    @window.refresh
  end

  def dev_draw(output)
    @dev_window.addstr(output.to_s + "\n")
    @dev_window.refresh
  end

  def input
    @window.getch
  end
end

Main.new.run
