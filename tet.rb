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
    @play_field = Array.new(20) { Array.new(10) { [:empty, false] } }
    @renderer = opts[:renderer]
    @input = opts[:input]
    @running = true
    @g_num = 0
    @block_list = [IBlock, OBlock, ZBlock]
    @flags = [:new_block]
  end

  def run
    begin
      @renderer.start
      @renderer.draw(@play_field)
      while @running
        handle_flags
        act(@input.manage)
        apply_gravity
        @renderer.draw(@play_field)
        sleep(1/60)
      end
    ensure
      @renderer.stop
    end
  end

  def handle_flags
    @flags.each { |flag| send(flag) }
    @flags.clear
  end

  def new_block
    @current_block = @block_list.sample.new(
      play_field: @play_field,
      flags: @flags
    )
    @current_block.spawn
  end

  def apply_gravity
    @g_num += 1
    if @g_num == 75
      @current_block.move(:down)
      @g_num = 0
    end
  end

  def act(input)
    send(input) unless input == nil
  end

  def move_left
    @current_block.move(:left)
  end

  def move_right
    @current_block.move(:right)
  end

  def move_down
    @current_block.move(:down)
  end

  def stop
    @running = false
  end
end

class Cell
  def initialize(opts)
    @pos = opts[:pos]
  end

  def [](index)
    @pos[index]
  end

  def []=(index, value)
    @pos[index] = value
  end
end

class Block
  def initialize(opts)
    @play_field = opts[:play_field]
    @flags = opts[:flags]
    @resting = false
  end

  def resting?
    @resting
  end

  def collision?
    @data.each do |cell|
     return true if cell[1] < 0
     return true if cell[1] > 9
     return true if cell[0] > 19
    end
    return false
  end

  def move(direction)
    directions = {left: [1, -1], right: [1, 1], down: [0, 1]}
    axis, delta = directions[direction]
    update_grid(type: :empty)
    @data.each { |cell| cell[axis] += delta }
    @data.each { |cell| cell[axis] -= delta } if collision?
    update_grid
  end

  def update_grid(type: @type, resting: @resting)
    @data.each { |cell| @play_field[cell[0]][cell[1]] = [type, resting]}
  end

  def spawn
    update_grid
  end
end

class IBlock < Block
  def initialize(opts)
    super
    @type = :i_block
    @data = [
      [5, 5],
      [6, 5],
      [7, 5],
      [8, 5]
    ].map { |pos| Cell.new(pos: pos, type: @type) }
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
    @type = :o_block
    @data = [
      [5, 5], [5, 6],
      [6, 5], [6, 6]
    ].map { |pos| Cell.new(pos: pos, type: @type) }
    @pos = [5, 5]
  end
end

class ZBlock < Block
  def initialize(opts)
    super
    @type = :z_block
    @data = [
      [5, 5], [5, 6],
              [6, 6], [6, 7]
    ].map { |pos| Cell.new(pos: pos, type: @type) }
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
    @type_map = {
      empty: "  ",
      i_block: "II",
      l_block: "LL",
      o_block: "OO",
      j_block: "JJ",
      s_block: "SS",
      t_block: "TT",
      z_block: "ZZ"
    }
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
          @window.addstr(@type_map[cell[0]])
        end
      end
    end
    @window.refresh
  end

  def input
    @window.getch
  end
end

class Debug
  def initialize
    @window = Curses::Window.new(30, 30, 0, 30)
    @window.setpos(0, 0)
  end

  def draw(output)
    @window.addstr(output.to_s + "\n")
    @window.refresh
  end

  def reset_pos
    @window.setpos(0, 0)
  end
end

$debug = Debug.new
Main.new.run
