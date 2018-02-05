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
    @play_field = Array.new(20) { Array.new(10) { 0 } }
    @renderer = opts[:renderer]
    @input = opts[:input]
    @running = true
    @g_num = 0
  end

  def run
    begin
      @renderer.start
      @current_block = ZBlock.new(play_field: @play_field)
      update_grid
      @renderer.draw(@play_field)
      while @running
        key = @input.manage
        act(key)
        # apply_gravity
        @renderer.draw(@play_field)
        sleep(1/60)
      end
    ensure
      @renderer.stop
    end
  end

  def apply_gravity
    @g_num += 1
    if @g_num == 75
      move_down
      @g_num = 0
    end
  end

  def act(input)
    send(input) unless input == nil
  end

  def move_left
    update_grid(0)
    @current_block.pos[1] -= 1
    @current_block.pos[1] += 1 if @current_block.oob?
    update_grid
  end

  def move_right
    update_grid(0)
    @current_block.pos[1] += 1
    @current_block.pos[1] -= 1 if @current_block.oob?
    update_grid
  end

  def move_down
    update_grid(0)
    @current_block.pos[0] += 1
    new_block if @current_block.at_rest?
    update_grid
  end

  def update_grid(override = nil)
    @current_block.data.each do |cell|
      y_pos = cell[1][0] + @current_block.pos[0]
      x_pos = cell[1][1] + @current_block.pos[1]
      @play_field[y_pos][x_pos] = override || cell[0]
    end
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
  end

  def oob?
    @data.each do |cell|
     return true if cell[1][1] + @pos[1] < 0
     return true if cell[1][1] + @pos[1] > 9
     # return true if cell[1][0] + @pos[0] > 19
    end
    return false
  end

  def at_rest?
    @data.each do |cell|
      y_pos = cell[0][0] + 1
      x_pos = cell[0][1]
      return true if @play_field[y_pos][x_pos] != 0
    end
  end
end

class OBlock < Block
  def initialize(opts)
    super
    @data = [
      [1, [0, 0]], [1, [0, 1]],
      [1, [1, 0]], [1, [1, 1]]
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
    @map = ["  ", "II", "LL", "OO", "RR", "SS", "TT", "ZZ"]
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
          @window.addstr(@map[cell])
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
