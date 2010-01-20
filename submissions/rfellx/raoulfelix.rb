=begin
Title:               Ruby Challenge #5
Program Description: Maze solving
Submitted By:        Raoul Felix
=end

class Maze
  # Initialize the Maze with a string containing the map
  # 
  def initialize(map)
    @map = map
  end
  
  # Returns +true+ if a solution was found for the maze and false otherwise
  #
  def solvable?
    !solution.empty?
  end
  
  # Returns the number of steps from point A to point B
  #
  def steps
    return 0 if solution.empty?
    # We have to subtract 1 because the starting position is in solution
    # e.g. Path 1,2,3,4 has 4 positions but only 3 steps: 1 to 2, 2 to 3, 3 to 4
    solution.length - 1
  end
  
  ### Additional Methods
  
  # Return an array of positions that go from A to B
  #
  def solution
    # The maze can't be changed, so it only needs to be solved once (lazy evaluation)
    @solution ||= solve
  end
  
  # Returns a string, just like the one passed to the Maze constructor, but has
  # the path from A to B filled with dots (.) to show the path that was taken.
  # Useful for debugging and visualization.
  #
  def solved_map
    str  = ""
    # Because Array#delete is destructive, we need to duplicate the solution array.
    # As the solution uses lazy evalutation and is only computed once, if we don't
    # duplicate the array and remove objects from the actual +solution+ then all
    # calls that rely on +solution+ after this will produce different and erroneous results.
    # Side-effects are bad!
    path = solution.dup
    maze.each_with_index do |row, y|
      row.each_with_index do |e, x|
        if path.delete([x,y]) && e != 'A' && e != 'B'
          str += "."
        else
          str += e
        end
      end
      str += "\n"
    end
    str
  end
  
  ### Helper Methods
  
  # Returns a bidimensional array of characters based on the maze string passed 
  # to the Maze constructor
  #
  def maze
    # Only deconstruct maze once
    @maze ||= deconstruct_maze
  end  
  
  # This solving methods uses a breadth-first search with a stack instead of 
  # recursion so it's not too slow.
  #
  def solve
    start, finish = find_start_and_finish
    stack         = [start]
    visited       = []
    while (stack.last != finish && !stack.empty?) do
      current_pos = stack.last
      moves       = possible_moves(current_pos)
      moves      -= stack # Remove any moves we've already taken
      moves      -= visited # Remove the moves that resulted in a dead-end
      if moves.empty?
        # Reached a dead-end, make sure we don't come here again
        visited << stack.pop
      else
        # Try the first move in the possible moves list
        stack << moves.first
      end
    end
    stack
  end
  
  # Transform the maze given as a string to the Maze constructor into a
  # bidimensional array of characters so it's easier to navigate through
  # 
  def deconstruct_maze
    @map.split("\n").map { |line| line.scan(/./) }
  end
  
  # Returns an array with two positions:
  #  - First is the start position (where A is)
  #  - Second is the finish position (where B is)
  # Positions are just arrays of length 2 that correspond to [x,y]
  # 
  def find_start_and_finish
    start, finish = nil, nil
    maze.each_with_index do |row,y|      
      row.each_with_index do |col,x|
        start = [x,y] if col == 'A'
        finish = [x,y] if col == 'B'
        return [start,finish] if start && finish
      end
    end
    raise "Start/Finish not properly specified"
  end
  
  # Returns an array with all positions that the algorithm can take given
  # the +pos+ passed as an argument. This method takes into account wall 
  # boundries and only navigates to positions where there is either one of 
  # these characters: ' ', A, and B.
  # Only top, right, bottom, and left moves are permitted.
  # 
  def possible_moves(pos)
    x,y       = pos
    width     = maze[0].length
    height    = maze.length
    positions = [
      [x  , y-1], # Top
      [x+1, y  ], # Right
      [x  , y+1], # Bottom
      [x-1, y  ]  # Left
    ].select do |x,y|
      x >= 0 && y >= 0 && x < width && y < height && [' ','A','B'].include?(maze[y][x])
    end
  end
end