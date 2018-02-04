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
  end

  def run
    begin
      @renderer.start
      @renderer.draw(@play_field)
      while @running
        spawn(OBlock.new)
        @renderer.draw(@play_field)
        @game.act(@input.manage)
        @running = false
      end
    ensure
      @renderer.stop
    end
  end

  def spawn(block)
    block.data.each do |cell|
      x_pos = cell[1][0] + block.pos[0]
      y_pos = cell[1][1] + block.pos[1]
      @play_field[x_pos][y_pos] = cell[0]
    end
  end
end

class Block
  attr_reader :data
  attr_accessor :pos
end

class OBlock < Block
  def initialize
    @data = [[1, [0, 0]], [1, [0, 1]], [1, [0, 1]], [1, [1, 1]]]
    @pos = [5, 5]
  end
end

class Input
  def initialize(opts)
    @source = opts[:source]
    @map = {
      move_left: "h"
    }
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
    @window = Curses::Window.new(22, 22, 0, 0)
    @window.box("|", "-")
    @window.keypad=(true)
    @map = ["  ", "00"]
  end

  def stop
    Curses.close_screen
  end

  def draw(grid)
    y_pos = 0
    grid.each do |row|
      y_pos += 1
      @window.setpos(y_pos, 1)
      row.each { |cell| @window.addstr(@map[cell]) }
    end
    @window.refresh
  end

  def input
    @window.getch
  end
end

Main.new.run
