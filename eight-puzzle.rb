# Sliding-block puzzle solver
#
# This code is the companion to the tutorial at:
# http://6brand.com/solving-8-puzzle-with-artificial-intelligence.html
#
# Send questions and comments to Jack Danger (http://jåck.com)
#
require 'benchmark'
require 'set'
require 'delegate'
require 'timeout'
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
    state.branches.reject do |branch|
      visited.include? branch.puzzle.cells
    end.each do |branch|
      frontier.add branch
    end
  end

  def progress!
   progress "nodes visited: #{visited.size}"
  end

  def solve puzzle
    state = self.class::State.new puzzle
    loop {
      progress!
      break if state.solution?
      search state
      return if frontier.length == 0
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

  def progress str
    print "\r"
    print str
    STDOUT.flush
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
  Queue = Array # this will not be unused

  def solve puzzle
    solved = nil
    error, depth = catch :blown_stack do
      solved = recurse self.class::State.new(puzzle)
    end
    if error
      puts " --> recursed #{depth} times"
      puts "     Failed with #{error}"
    end
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
end

class DepthFirst < Algorithm
  def solve puzzle
    Timeout.timeout(60) { super }
  rescue Timeout::Error
    puts " --> explored #{visited.size} nodes"
    puts "     left #{frontier.size} unexplored nodes"
    puts "     timed out after 60 seconds"
  end

  class Queue < DelegateClass(Array)
    def initialize
      super []
    end

    def pop # this is a LIFO stack
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

    def pop # this is a FIFO queue
      shift # remove front element
    end

    def add item
      push item # and add to the back
    end
  end
end

class UniformCostSearch < Algorithm
  class Queue < DelegateClass(PriorityQueue)
    def initialize(*args)
      super PriorityQueue.new
    rescue ArgumentError # Rubinius doesn't do DelegateClass#super right
      @_dc_obj = PriorityQueue.new
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
    rescue ArgumentError # Rubinius doesn't do DelegateClass#super right
      @_dc_obj = PriorityQueue.new
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

class IterativeDepthFirst < Algorithm
  # This is the same as depth-first but we slowly expand how
  # deep we're willing to travel. The order of nodes visited is
  # actually very similar to breadth-first.
  def solve puzzle
    @cutoff = 0
    puts ''
    begin
      progress "IDA cutoff: #{@cutoff}"
      @visited = Set.new
      @frontier = self.class::Queue.new(@cutoff+=1)
      @frontier.add self.class::State.new(puzzle)
      solved = super
    end until solved
    puts ''
    solved
  end

  def progress!; end

  class Queue < DelegateClass(Array)
    def initialize cutoff = 1
      @cutoff = cutoff
      super []
    end

    def pop # this is a LIFO stack
      shift # remove front element
    end

    def add item
      if item.path.size <= @cutoff
        unshift item # Only add to the stack if it's not too deep
      end
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
  puts "  found in : #{"%0.4f" % timing.utime} seconds"
  puts "  we checked: #{algorithm.visited.size} states"
  puts "  we generated: #{algorithm.frontier.length} as-yet-unexplored states"
end
