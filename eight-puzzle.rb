require 'set'

def coords index
  # turn a 0-8 index into the x,y coordinates
  # of a 3x3 grid
  [index % 3, (index / 3).to_i]
end

class State
  Directions = [:left, :right, :up, :down]

  attr_reader :puzzle, :path

  def initialize(puzzle, path = [])
    @puzzle, @path = puzzle, path
  end

  def solution?
    puzzle.solution?
  end

  def branches
    Directions.map do |dir|
      cell = branch_toward dir
      State.new puzzle.swap(cell), @path << dir if cell
    end.compact
  end

  private

  def branch_toward direction
    blank_position = puzzle.zero_position
    blankx, blanky = coords blank_position
    case direction
    when :left
      blank_position - 1 unless 0 == blankx
    when :right
      blank_position + 1 unless 3 == blankx
    when :up
      blank_position - 3 unless 0 == blanky
    when :down
      blank_position + 3 unless 3 == blanky
    end
  end
end

class Puzzle
  Solution = [0, 1, 2, 3, 4, 5, 6, 7, 8]
  def initialize cells
    @cells = cells
  end

  def solution?
    Solution == @cells
  end

  def zero_position
    @cells.take_while {|c| c > 0}.size
  end

  # swap the given cell (by index) with the
  # cell containg zero
  def swap swap_index
    new_cells = @cells.clone
    new_cells[zero_position] = new_cells[swap_index]
    new_cells[swap_index] = 0
    Puzzle.new new_cells
  end
end


def search state
  branches = state.branches.reject do |branch|
    @visited.include? branch.puzzle
  end.each do |branch|
    @frontier << branch
  end
end

def solve puzzle
  @visited = Set.new
  @frontier = []
  state = State.new puzzle
  loop {
    break if state.solution?
    search state
    state = @frontier.shift
  }
  state
end

p solve(Puzzle.new [1, 4, 2, 3, 0, 5, 6, 7, 8])
