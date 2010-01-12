require File.join(File.expand_path(File.dirname(__FILE__)), "spec_helper.rb")
require 'fixtures'

describe Maze do
  context "#deconstruct_maze" do
    it "should return a bidimensional array" do
      map = "###\n# #\n###"
      maze = Maze.new(map)
      deconstructed_maze = [['#', '#', '#'], ['#', ' ', '#'], ['#', '#', '#']]
      maze.deconstruct_maze.should == deconstructed_maze
    end
  end
  
  context "#find_start_and_finish" do
    it "should find A as start and B as finish" do
      maze = Maze.new(SIMPLE1)
      maze.find_start_and_finish.should == [[1,1], [1,3]]
    end
    
    it "should raise an error when there are problems with start and finish" do
      lambda { Maze.new('###').find_start_and_finish }.should raise_error
      lambda { Maze.new('A').find_start_and_finish }.should raise_error
      lambda { Maze.new('B').find_start_and_finish }.should raise_error
      lambda { Maze.new('').find_start_and_finish }.should raise_error
    end
  end
  
  context "#possible_moves" do
    before(:each) do
      @maze = Maze.new(SIMPLE1)
    end

    it "should find no possible moves" do
      pos = [0,0]
      @maze.possible_moves(pos).should == []
      pos = [5,0]
      @maze.possible_moves(pos).should == []
    end
    
    it "should find 1 possible move" do
      pos = [1,1]
      @maze.possible_moves(pos).should == [[2,1]]
      pos = [5,1]
      @maze.possible_moves(pos).should == [[4,1]]
    end
    
    it "should find 2 possible moves" do
      pos = [2,1]
      @maze.possible_moves(pos).should == [[3,1], [1,1]]
      pos = [4,1]
      @maze.possible_moves(pos).should == [[4,2], [3,1]]
      pos = [4,2]
      @maze.possible_moves(pos).should == [[4,1], [4,3]]
    end
    
  end

  context "#solve" do
    it "should find a path for SIMPLE1" do
      Maze.new(SIMPLE1).solve.should == [
        [1,1], [2,1], [3,1], [4,1],
        [4,2],
        [4,3], [3,3], [2,3], [1,3]
      ]
    end
    
    it "should not find a path for SIMPLE2" do
      Maze.new(SIMPLE2).solve.should == []
    end
  end
  
  context "#solved_map" do
    it "should print the path taken in simple maze 1" do
      Maze.new(SIMPLE1).solved_map.should == SOLVED_SIMPLE1
    end
  end
end

describe Maze, "#solvable?" do
  context "solvable mazes" do
    it "should say simple maze 1 is solvable" do
      Maze.new(SIMPLE1).solvable?.should be_true
    end
    it "should say maze 1 is solvable" do
      Maze.new(MAZE1).solvable?.should be_true
    end
    it "should say maze 2 is solvable" do
      Maze.new(MAZE2).solvable?.should be_true
    end
  end
  
  context "unsolvable mazes" do
    it "should say simple maze 2 is not solvable" do
      Maze.new(SIMPLE2).solvable?.should be_false
    end    
    it "should say maze 3 is not solvable" do
      Maze.new(MAZE3).solvable?.should be_false
    end
  end
end

describe Maze, "#steps" do
  context "solvable mazes" do
    it "should say simple maze 1 needs 8 steps" do
      Maze.new(SIMPLE1).steps.should == 8
    end
    it "should say simple maze 3 needs 14 steps" do
      Maze.new(SIMPLE3).steps.should == 14
    end    
    it "should say maze 1 needs 44 steps" do
      maze = Maze.new(MAZE1)
      maze.steps.should == 44
    end
    it "should say maze 2 needs 75 steps" do
      Maze.new(MAZE2).steps.should == 75
    end
  end
  
  context "unsolvable mazes" do
    it "should say simple maze 2 needs 0 steps" do
      Maze.new(SIMPLE2).steps.should == 0
    end
    it "should say maze 3 needs 0 steps" do
      Maze.new(MAZE3).steps.should == 0
    end
  end  
end