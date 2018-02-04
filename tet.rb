require 'curses'

class Main
  attr_accessor :play_field
  def initialize(opts)
    @renderer = opts[:renderer]
    @input = opts[:input]
    @play_field = Array.new(10) { Array.new(20) { 0 } }
  end

  def run
    begin
      @renderer.start
      button = @input.manage
    ensure
      @renderer.stop
    end
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
    @window = Curses::Window.new(22, 12, 0, 0)
    @window.box("|", "-")
    @window.keypad=(true)
  end

  def stop
    Curses.close_screen
  end

  def draw(grid)
    grid.each { |line|  }
  end

  def input
    @window.getch
  end
end

renderer = Renderer.new
input = Input.new(source: renderer)
main = Main.new(renderer: renderer, input: input)
main.run


  # def manage_input(input)
    # case input
    # when "l", Curses::Key::RIGHT
      # @player.move("right")
    # when "h", Curses::Key::LEFT
      # @player.move("left")
    # when "k", Curses::Key::UP
      # @player.move("up")
    # when "j", Curses::Key::DOWN
      # @player.move("down")
    # when "q"
      # @running = false
    # end
  # end
