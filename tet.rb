require 'curses'

class Main
  def initialize
    state = State.new
    renderer = Renderer.new
    input = Input.new(source: renderer)
    actions = {
      move_down: Actions::MoveDown.new,
      move_left: Actions::MoveLeft.new,
      move_right: Actions::MoveRight.new,
      spawn: Actions::Spawn.new,
      stop: Actions::Stop.new
    }
    @game = Game.new(
      renderer: renderer, input: input, actions: actions, state: state
    )
  end

  def run
    @game.run
  end
end

class Game
  def initialize(opts)
    @renderer = opts[:renderer]
    @input = opts[:input]
    @g_num = 0
    @block_list = [IBlock, OBlock, ZBlock]
    @actions = opts[:actions]
    @state = opts[:state]
    @state.play_field = Array.new(20) { Array.new(10) { [:empty, false] } }
    @state.running = true
    @state.flags = [:new_block]
  end

  def run
    begin
      @renderer.start
      @renderer.draw(@state.play_field)
      tick while @state.running
    ensure
      @renderer.stop
    end
  end

  def tick
    handle_flags
    act(@input.manage)
    apply_gravity
    @renderer.draw(@state.play_field)
    sleep(1/60)
  end

  def handle_flags
    @state.flags.each { |flag| send(flag) }
    @state.flags.clear
  end

  def new_block
    @state.block = @block_list.sample.new
    act(:spawn)
  end

  def apply_gravity
    @g_num += 1
    if @g_num == 75
      act(:move_down)
      @g_num = 0
    end
  end

  def act(input)
    @actions[input].act(@state) unless input == nil
  end
end

class State
  attr_accessor :running, :flags, :block, :play_field

  def initialize
    @running = nil
    @flags = nil
    @block = nil
    @play_field = nil
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

module Actions
  class Action
    def update_grid(state, type)
      state.block.data.each { |cell| state.play_field[cell[0]][cell[1]] = [type, false]}
    end

    def collision?(state)
      state.block.data.each do |cell|
       return true if cell[1] < 0
       return true if cell[1] > 9
       return true if cell[0] > 19
      end
      return false
    end
  end

  class MoveDown < Action
    def act(state)
      update_grid(state, :empty)
      state.block.data.each { |cell| cell[0] += 1 }
      if collision?(state)
        state.block.data.each { |cell| cell[0] -= 1 }
        state.flags << :new_block
      end
      update_grid(state, state.block.type)
    end
  end

  class MoveLeft < Action
    def act(state)
      update_grid(state, :empty)
      state.block.data.each { |cell| cell[1] -= 1 }
      state.block.data.each { |cell| cell[1] += 1 } if collision?(state)
      update_grid(state, state.block.type)
    end
  end

  class MoveRight < Action
    def act(state)
      update_grid(state, :empty)
      state.block.data.each { |cell| cell[1] += 1 }
      state.block.data.each { |cell| cell[1] -= 1 } if collision?(state)
      update_grid(state, state.block.type)
    end
  end

  class Spawn < Action
    def act(state)
      update_grid(state, state.block.type)
    end
  end

  class Stop
    def act(state)
      state.running = false
    end
  end
end

class IBlock
  attr_reader :type, :data

  def initialize
    @type = :i_block
    @data = [
      [5, 5],
      [6, 5],
      [7, 5],
      [8, 5]
    ].map { |pos| Cell.new(pos: pos, type: @type) }
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

class OBlock
  attr_reader :type, :data

  def initialize
    @type = :o_block
    @data = [
      [5, 5], [5, 6],
      [6, 5], [6, 6]
    ].map { |pos| Cell.new(pos: pos, type: @type) }
  end
end

class ZBlock
  attr_reader :type, :data

  def initialize
    @type = :z_block
    @data = [
      [5, 5], [5, 6],
              [6, 6], [6, 7]
    ].map { |pos| Cell.new(pos: pos, type: @type) }
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
