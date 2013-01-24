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
require 'inline'
require 'timeout'
require 'priority_queue'

Size = ARGV.last == '15' ? 4 : 3

class Cells < Array
  # Give this an optimal hash code for fast Set and Hash lookups.
  # We get a speedup out of knowing there are Size*Size distinct integers.
  inline(:C) do |builder|
    builder.c <<-CCode
      int hash() {
        VALUE *list = RARRAY_PTR(self);
        return #{
          (Size*Size).times.map {|n|
            "list[#{n}] * 1#{"0"*n}"
          }.join(" + \n")};
          // list[0] * 1        +
          // list[1] * 10       +
          // list[2] * 100      +
          // list[3] * 1000     +
          // list[4] * 10000    +
          // list[5] * 100000   +
          // list[6] * 1000000  +
          // list[7] * 10000000 +
          // list[8] * 100000000;
      }
CCode
  end
  # def hash
  #  self[0] * 1        +
  #  self[1] * 10       +
  #  self[2] * 100      +
  #  self[3] * 1000     +
  #  self[4] * 10000    +
  #  self[5] * 100000   +
  #  self[6] * 1000000  +
  #  self[7] * 10000000 +
  #  self[8] * 100000000
  #end
end
class Puzzle

  Solution = Cells.new 0.upto(Size*Size-1).to_a

  attr_reader :cells

  def initialize cells
    @cells = cells
  end

  def solution?
    Solution == cells
  end

  def distance_to_goal
    @distance_to_goal ||= begin
      cells.zip(Solution).inject(0) do |sum, (a,b)|
        sum += manhattan_distance a % Size, a / Size,
                                  b % Size, b / Size
      end
    end
  end

  def zero_position
    @zero_position ||= cells.index 0
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

  #def manhattan_distance(x1, y1, x2, y2)
  #  (x1 - x2).abs + (y1 - y2).abs
  #end
  ## Writing this in C because it's 25% of the run time otherwise.
  ## We want to see how the algorithms chosen affect speed, not how
  ## Ruby can be slow.
  inline(:C) do |builder|
    builder.c "
      int manhattan_distance(int x1, int y1,
                             int x2, int y2) {
        int x = x1 - x2;
        int y = y1 - y2;
        return (x < 0 ? -x : x) + ( y < 0 ? -y : y);
      }
    "
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
    puts ''
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
      blankx = blank_position % Size
      blanky = (blank_position / Size).to_i
      cell = case direction
      when :left
        blank_position - 1 unless 0 == blankx
      when :right
        blank_position + 1 unless (Size-1) == blankx
      when :up
        blank_position - Size unless 0 == blanky
      when :down
        blank_position + Size unless (Size-1) == blanky
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
    start = self.class::State.new(puzzle)
    cutoff = 0
    begin
      progress "IDA cutoff: #{cutoff}"
      @visited = Set.new
      @frontier = self.class::Queue.new(cutoff+=1)
      @frontier.add start
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

class IterativeAStar < Algorithm
  Infinity = 1/0.0
  Queue = Array
  # We combine the best of A* and the best of
  # Iterative Deepening Search. We proceed depth-first
  # with a gradually-increasing cutoff and a priority
  # queue sorted by both path cost and distance to goal.
  def solve puzzle
    start = self.class::State.new(puzzle)
    max_cost = start.cost
    begin
      progress "IDA* max cost: #{max_cost}"
      @visited = Hash.new
      solved, max_cost = recurse start, max_cost
    end until solved
    puts ''
    solved
  end

  def recurse state, max_cost
    visited[state.puzzle.cells] = state.cost
    return nil, state.cost if state.cost > max_cost
    return state, max_cost if state.solution?
    next_best_cost = Infinity
    solutions = []
    state.branches.each do |branch|
      next if (visited[branch.puzzle.cells] || Infinity) < branch.cost
      solved, deeper_cost = recurse branch, max_cost
      solutions << [solved, branch.cost] if solved
      next_best_cost = [next_best_cost, deeper_cost].min
    end
    if solutions.any?
      return solutions.sort_by {|_, cost| cost }.first
    end
    return nil, next_best_cost
  end

  def progress!; end

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

state = Algorithm::State.new Puzzle.new(Puzzle::Solution)
2000.times { state = state.branches.sample }
path = [:up, :up, :right, :down, :right, :down, :left, :left, :up, :up, :right, :down, :down, :right, :up, :left, :down, :left, :up, :up]
p state.path
p state.puzzle
#root = solveable(state.path)
root = state

#Algorithm.subclasses.each do |klass|
[IterativeAStar].each do |klass|
  puts klass
  algorithm = klass.new

  found = nil
  timing = Benchmark.measure do
    solution = algorithm.solve(root.puzzle)
    found = solution.path if solution
  end
  next unless found
  p found

  puts  "  found in : #{"%0.4f" % timing.utime} seconds"
  puts  "  we checked: #{algorithm.visited.size} states"
  puts  "  we generated: #{algorithm.frontier.length} as-yet-unexplored states"
end
