#!/usr/bin/env ruby
# encoding: utf-8
require 'curses'
class Game
  attr_accessor :renderer
  attr_reader :board, :generation
  def initialize seed_cells=nil
    @board = Board.new()
    @generation = 0
    @renderer = ArrayRenderer
    seed! seed_cells
  end

  def seed! seed_cells=nil
    board.seed! seed_cells
  end

  def advance!
    next_board = Board.new()
    board.significant_cells.each do |cell|
      next_board.cell_at(cell.x, cell.y, cell.will_live?)
    end
    @generation += 1
    @board = next_board
  end
  def play(max=nil, draw_generations=false)
    enumerator = max ? max.times : loop
    enumerator.each do
      puts "\n" + render[0..(-2-generation.to_s.length)] + " #{generation}" if draw_generations
      render
      advance!
      sleep (1.0/24)
    end
  end
  def render
    renderer.render(board)
  end
end

class Board
  attr_reader :generation, :rows, :game
  attr_accessor :renderer

  def initialize(seed_cells=nil)
    seed! seed_cells
  end

  def row(key)
    @rows[key] ||= {}
  end

  def cell_at(x, y, living=nil)
    row(x)[y] ||= Cell.new(living, self, x, y)
  end
  alias_method :[], :cell_at

  def neighbours_of(x,y)
    [self[x-1, y-1], self[x, y-1], self[x+1, y-1],
     self[x-1, y  ],               self[x+1, y  ],
     self[x-1, y+1], self[x, y+1], self[x+1, y+1]]
  end
  alias_method :neighbors_of, :neighbours_of

  def significant_cells
    cells = @rows.values.map(&:values).flatten
    living_cells = cells.select(&:alive?)
    neighbouring_cells = living_cells.map(&:neighbours).flatten
    (living_cells + neighbouring_cells).uniq
  end

  def seed! seed_cells=nil
    @rows = {}
    if seed_cells
      seed_cells.each_with_index do |row, y|
        row.each_with_index do |cell, x|
          cell_at x, y, cell == 1 ? true : false
        end
      end
    end
  end
end

class ArrayRenderer
  attr_accessor :living, :dead, :board
  def initialize
    @living = 1
    @dead = 0
  end

  def rows
    keys = @board.rows.keys
    keys.min..keys.max
  end
  def columns
    keys = @board.rows.values.map(&:keys).flatten
    keys.min..keys.max
  end

  def seed board=@board, seed_cells=nil
    @board=board
    @board.rows = {}
    if seed_cells
      seed_cells.each_with_index do |row, y|
        row.each_with_index do |cell, x|
          @board.cell_at x, y, cell == @living ? true : false
        end
      end
    end
  end

  def render(board=@board)
    @board=board
    a = []
    y_offset = 0 - columns.first
    x_offset = 0 - rows.first
    rows.each do |x|
      columns.each do |y|
        a[y + y_offset] ||= []
        a[y + y_offset][x + x_offset] = @board[x,y].alive? ? living : dead
      end
    end
    a
  end
end

class TextRenderer
  attr_accessor :living, :dead, :board,
                :width, :height,
                :print_coordinates
  require 'hirb'
  def initialize(width=nil,height=nil)
    @width = width || Hirb::View.width
    @height = height || Hirb::View.height
    @living = '▓'
    @dead = '░'
  end

  def render(board=@board)
    @board=board
    t = ''
    y_offset = 0 - ((height - 1).to_f / 2).to_i
    x_offset = 0 - ((width  - 1).to_f / 2).to_i
    if @print_coordinates
      t += "  "
      width.times do |y|
        t += y.to_s.split('').last
      end
      t += "\n"
    end
    height.times do |y|
      t += "#{y}:" if @print_coordinates
      width.times do |x|
        t += @board[x+x_offset, y+y_offset].alive? ? @living : @dead
      end
      t += "\n"
    end
    t.chomp
  end
end

class CursesRenderer
  attr_accessor :living, :dead, :board,
                :print_coordinates,
                :width, :height
  def initialize(width=nil,height=nil)
    @width = width
    @height = height
    @living = '#'
    @dead = ' '
  end

  def render(board=@board)
    @board=board
    t = ''
    y_offset = 0 - ((height - 1).to_f / 2).to_i
    x_offset = 0 - ((width  - 1).to_f / 2).to_i
    Curses.clear
    height.times do |y|
      width.times do |x|
        Curses.setpos(y,x)
        Curses.addstr @board[x+x_offset, y+y_offset].alive? ? @living : @dead
      end
    end
    Curses.refresh
  end
end

class Cell
  attr_reader :x, :y
  attr_accessor :living

  def initialize(living = nil, board=nil, x=0, y=0)
    @x = x
    @y = y
    @board = board
    @living = living
  end

  def alive?
    @living
  end
  def dead?
    !alive?
  end

  def live!
    @living = true
  end
  def die!
    @living = false
  end

  def neighbours
    @board.neighbours_of(@x,@y)
  end
  alias_method :neighbors, :neighbours

  def living_neighbours
    neighbours.select(&:alive?).length
  end
  alias_method :living_neighbors, :living_neighbours

  def will_live?
    alive? && (2..3) === living_neighbours || dead? && 3 == living_neighbours
  end

  def will_die?
    !will_live?
  end
end