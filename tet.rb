require "curses"

class Main
  def initialize
    renderer = Renderer.new
    @game = Game.new(
      renderer: renderer, input: Input.new(source: renderer), state: State.new,
      block_list: [
        Blocks::IBlock, Blocks::OBlock, Blocks::ZBlock, Blocks::LBlock,
        Blocks::SBlock, Blocks::JBlock, Blocks::TBlock
      ],
      play_field: Array.new(20) { Array.new(10) { :empty } },
      actions: {
        move_down: Actions::MoveDown.new, move_left: Actions::MoveLeft.new,
        move_right: Actions::MoveRight.new, stop: Actions::Stop.new,
        rotate_cw: Actions::RotateClockwise.new,
        rotate_ccw: Actions::RotateCounterClockwise.new
      }
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
    @block_list = opts[:block_list]
    @actions = opts[:actions]
    @state = opts[:state]
    @state.play_field = opts[:play_field]
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
    @state.update_grid
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

  def update_grid(type = @block.type)
    @block.data.each { |cell| @play_field[cell[0]][cell[1]] = type}
  end

  def check_collision
    @block.data.each do |cell|
     return true if cell[1] < 0
     return true if cell[1] > 9
     return true if cell[0] > 19
     return true if @play_field[cell[0]][cell[1]] != :empty
    end
    return false
  end
end

module Actions
  class Action
    def initialize
      @collision = false
    end
  end

  class Move < Action
    def move(state, axis, delta)
      state.update_grid(:empty)
      state.block.pos[axis] += delta
      @collision = state.check_collision
      state.block.pos[axis] -= delta if @collision
      state.update_grid
    end
  end

  class MoveDown < Move
    def act(state)
      move(state, 0, 1)
      state.flags << :new_block if @collision
    end
  end

  class MoveLeft < Move
    def act(state)
      move(state, 1, -1)
    end
  end

  class MoveRight < Move
    def act(state)
     move(state, 1, 1)
    end
  end

  class Rotate
    def rotate(state, direction)
      state.update_grid(:empty)
      state.block.states.rotate!(direction)
      state.block.data = state.block.states[0]
      @collision = state.check_collision
      if @collision
        state.block.states.rotate!(-(direction))
        state.block.data = state.block.states[0]
      end
      state.update_grid
    end
  end

  class RotateClockwise < Rotate
    def act(state)
      rotate(state, 1)
    end
  end

  class RotateCounterClockwise < Rotate
    def act(state)
      rotate(state, -1)
    end
  end

  class Stop
    def act(state)
      state.running = false
    end
  end
end

module Blocks
  class Block
    attr_reader :type
    attr_accessor :pos, :states
    attr_writer :data

    def data
      @data.map { |cell| [cell[0] + @pos[0], cell[1] + @pos[1]] }
    end
  end

  class IBlock < Block
    def initialize
      @type = :i_block
      @pos = [3, 3]
      @states = [
        [[1, 0], [1, 1], [1, 2], [1, 3]],
        [[0, 2], [1, 2], [2, 2], [3, 2]],
        [[2, 0], [2, 1], [2, 2], [2, 3]],
        [[0, 1], [1, 1], [2, 1], [3, 1]]
      ]
      @data = @states[0]
    end
  end

  class LBlock < Block
    def initialize
      @type = :l_block
      @pos = [3, 3]
      @states = [
        [[0, 2], [1, 0], [1, 1], [1, 2]],
        [[0, 1], [1, 1], [2, 1], [2, 2]],
        [[1, 0], [1, 1], [1, 2], [2, 0]],
        [[0, 0], [0, 1], [1, 1], [2, 1]]
      ]
      @data = @states[0]
    end
  end

  class JBlock < Block
    def initialize
      @type = :j_block
      @pos = [3, 3]
      @states = [
       [[0, 0], [1, 0], [1, 1], [1, 2]],
       [[0, 1], [0, 2], [1, 1], [2, 1]],
       [[1, 0], [1, 1], [1, 2], [2, 2]],
       [[0, 1], [1, 1], [2, 0], [2, 1]]
      ]
      @data = @states[0]
    end
  end

  class OBlock < Block
    def initialize
      @type = :o_block
      @pos = [3, 3]
      @states = [
        [[0, 0], [0, 1], [1, 0], [1, 1]]
      ]
      @data = @states[0]
    end
  end

  class ZBlock < Block
    def initialize
      @type = :z_block
      @pos = [3, 3]
      @states = [
        [[0, 0], [0, 1], [1, 1], [1, 2]],
        [[0, 2], [1, 1], [1, 2], [2, 1]],
        [[1, 0], [1, 1], [2, 1], [2, 2]],
        [[0, 1], [1, 0], [1, 1], [2, 0]]
      ]
      @data = @states[0]
    end
  end

  class SBlock < Block
    def initialize
      @type = :s_block
      @pos = [3, 3]
      @states = [
        [[0, 1], [0, 2], [1, 0], [1, 1]],
        [[0, 1], [1, 1], [1, 2], [2, 2]],
        [[1, 1], [1, 2], [2, 0], [2, 1]],
        [[0, 0], [1, 0], [1, 1], [2, 1]]
      ]
      @data = @states[0]
    end
  end

  class TBlock < Block
    def initialize
      @type = :t_block
      @pos = [3, 3]
      @states = [
       [[0, 1], [1, 0], [1, 1], [1, 2]],
       [[0, 1], [1, 1], [1, 2], [2, 1]],
       [[1, 0], [1, 1], [1, 2], [2, 1]],
       [[0, 1], [1, 0], [1, 1], [2, 1]]
      ]
      @data = @states[0]
    end
  end
end

class Input
  def initialize(opts)
    @source = opts[:source]
    @map = {
      move_left: "h",
      move_right: "l",
      move_down: "j",
      rotate_cw: "s",
      rotate_ccw: "a",
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
          @window.addstr(@type_map[cell])
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
    @window = Curses::Window.new(30, 60, 0, 30)
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
