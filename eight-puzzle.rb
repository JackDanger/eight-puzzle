require 'benchmark'
require 'set'
require 'delegate'
# add 'PriorityQueue' to your C-Ruby Gemfile
require 'priority_queue'


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
    cells.index 0
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

class Algorithm

  attr_reader :visited, :frontier

  def initialize
    @visited = Set.new
    @frontier = self.class::Queue.new
  end

  def search state
    visited << state.puzzle.cells
    if visited.size % 5000 == 0
      puts "  visited: #{visited.size}"
    end
    state.branches.reject do |branch|
      visited.include? branch.puzzle.cells
    end.each do |branch|
      frontier.add branch
    end
  end

  def solve puzzle
    state = self.class::State.new puzzle
    loop {
      break if state.solution?
      search state
      state = frontier.pop
    }
    state
  end

  def self.inherited(subclass)
    subclasses << subclass
  end

  def self.subclasses
    @subclasses ||= []
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
      self.class.new puzzle.swap(cell), @path + [direction] if cell
    end
  end
end

class RecursiveDepthFirst < Algorithm
  def solve puzzle
    solved = nil
    error, depth = catch :blown_stack do
      solved = recurse self.class::State.new(puzzle)
    end
    puts " --> recursed #{depth} times"
    p error
    solved
  end

  def recurse state, depth = 0
    state.branches.reject do |branch|
      visited.include? branch.puzzle.cells
    end.each do |branch|
      recurse branch, depth + 1
    end
  rescue SystemStackError => error
    throw :blown_stack, [error, depth]
  end

  class Queue < DelegateClass(Array)
    def initialize
      super []
    end

    def pop
      shift # remove front element
    end

    def add item
      unshift item # and add to the front, too
    end
  end
end

class BreadthFirst < Algorithm
  class Queue < DelegateClass(Array)
    def initialize
      super []
    end

    def pop
      shift # remove front element
    end

    def add item
      push item # and add to the back
    end
  end
end

class UniformCostSearch < Algorithm
  class Queue < DelegateClass(PriorityQueue)
    def initialize
      super PriorityQueue.new
    end

    def pop
      delete_min.first
    end

    def add item
      push item, item.cost
    end
  end

  class State < Algorithm::State
    def cost
      path.size
    end
  end
end

class AStarSearch < Algorithm
  class Queue < DelegateClass(PriorityQueue)
    def initialize
      super PriorityQueue.new
    end

    def pop
      delete_min.first
    end

    def add item
      push item, item.cost
    end
  end

  class State < Algorithm::State
    def cost
      g + h
    end

    def g
      path.size
    end

    def h
      puzzle.distance_to_goal
    end
  end
end


# Generate a solveable starting puzzle
def solveable(path)
  map = {
    :right => :left,
    :left  => :right,
    :up    => :down,
    :down  => :up
  }
  state = Algorithm::State.new(Puzzle.new(Puzzle::Solution), [])
  path.reverse.each {|step|
    direction = map[step]
    state = state.branch_toward direction
  }
  state
end

path = [:up, :up, :right, :down, :right, :down, :left, :left, :up, :up, :right, :down, :down, :right, :up, :left, :down, :left, :up, :up]
root = solveable(path)
Algorithm.subclasses.each do |klass|
  puts klass
  algorithm = klass.new

  found = nil
  timing = Benchmark.measure do
    solution = algorithm.solve(root.puzzle)
    found = solution.path if solution
  end
  next unless found
  puts "  found in : #{timing.inspect}"
  puts "  given a #{path.size}-step seed"
  puts "  we found a matching #{found.size}-step path"
  puts "  we checked: #{algorithm.visited.size} states"
  puts "  we generated: #{algorithm.frontier.length} as-yet-unexplored states"
end
