require 'benchmark'
require 'set'

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
    Directions.map do |direction|
      branch_toward direction
    end.compact.shuffle
  end

  def branch_toward direction
    blank_position = puzzle.zero_position
    blankx = blank_position % 3
    blanky = (blank_position / 3).to_i
    cell = case direction
    when :left
      blank_position - 1 unless 0 == blankx
    when :right
      blank_position + 1 unless 2 == blankx
    when :up
      blank_position - 3 unless 0 == blanky
    when :down
      blank_position + 3 unless 2 == blanky
    end
    State.new puzzle.swap(cell), @path + [direction] if cell
  end
end

class Puzzle
  Solution = [0, 1, 2, 3, 4, 5, 6, 7, 8]
  attr_reader :cells
  def initialize cells
    @cells = cells
  end

  def solution?
    Solution == cells
  end

  def distance_to_goal
    cells.zip(Solution).inject(0) do |sum, (a,b)|
      sum += manhattan_distance a % 3, (a / 3).to_i,
                                b % 3, (b / 3).to_i
    end
  end

  def zero_position
    cells.take_while {|c| c > 0}.size
  end

  # swap the given cell (by index) with the
  # cell containg zero
  def swap swap_index
    new_cells = cells.clone
    new_cells[zero_position] = new_cells[swap_index]
    new_cells[swap_index] = 0
    Puzzle.new new_cells
  end

  private

  def manhattan_distance x1, y1, x2, y2
    (x1 - x2).abs + (y1 - y2).abs
  end
end


# add 'PriorityQueue' to your C-Ruby Gemfile
require 'priority_queue'

class State
  def cost                           # The cost is pretty simple to calculate here.
    h + path.size                    # The path contains all the steps, in order that we
  end                                # used to arrive at this state.
  def h
    puzzle.distance_to_goal
  end
end

def search state
  @visited << state.puzzle.cells
  branches = state.branches.reject do |branch|
    @visited.include? branch.puzzle.cells
  end.each do |branch|
    @frontier.push branch, branch.cost
  end
end

def solve puzzle
  @visited = Set.new
  @frontier = PriorityQueue.new
  state = State.new puzzle
  loop {
    break if state.solution?
    search state
    state = @frontier.delete_min.first
  }
  state
end

# The following is the code that runs the solver runner

def solveable(path)
  map = {
    right: :left,
    left:  :right,
    up:    :down,
    down:  :up
  }
  state = State.new(Puzzle.new(Puzzle::Solution), [])
  path.reverse.each {|step|
    direction = map[step]
    state = state.branch_toward direction
  }
  state
end

path = [:up, :up, :right, :down, :right, :down, :left, :left, :up, :up, :right, :down, :down, :right, :up, :left, :down, :left, :up, :up]
root = solveable(path)
found = nil
timing = Benchmark.measure do
  found = solve(root.puzzle).path
end
puts "found in : #{timing.inspect}"
puts "given a #{path.size}-step seed"
puts "we found a matching #{found.size}-step path"
puts "we checked: #{@visited.size} states"
puts "we generated: #{@frontier.length} as-yet-unexplored states"
