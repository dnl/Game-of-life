require "rspec"
require_relative '../lib/game_of_life.rb'
describe "cell" do
  before :each do
    @cell = Cell.new
  end
  it "should default to dead" do
    @cell.dead?.should be_true
  end
  it "should become alive" do
    @cell.live!
    @cell.alive?.should be_true
  end
  it "should die again" do
    @cell.die!
    @cell.dead?.should be_true
    @cell.alive?.should be_false
    @cell.live!
    @cell.alive?.should be_true
    @cell.die!
    @cell.alive?.should be_false
  end
  
  # Any live cell with fewer than two live neighbours dies, as if caused by under-population.
  # Any live cell with two or three live neighbours lives on to the next generation.
  # Any live cell with more than three live neighbours dies, as if by overcrowding.
  # Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.
  it "should die if it has 0 or 1 living neighbours" do
    @board = Board.new [[0,1,0],
                        [0,1,0],
                        [0,0,0],
                        [0,1,0]]
    @board[1,1].will_die?.should be_true
    @board[1,3].will_die?.should be_true
  end
  it "should remain alive if it has 2 or 3 living neighbours" do
    @board = Board.new [[0,1,0],
                        [1,1,0],
                        [0,1,0]]
    @board[1,1].will_live?.should be_true
    @board[2,1].will_live?.should be_true
  end
  it "should die if it has 4-8 living neighbours" do
    @board = Board.new [[1,1,0],
                        [1,1,0],
                        [1,1,1]]
    @board[1,1].will_die?.should be_true
    @board[1,2].will_die?.should be_true
  end
  it "should become alive if it has 3 living neighbours" do
     @board = Board.new [[0,1,0],
                         [1,1,0],
                         [0,1,0]]
     @board[2,1].will_live?.should be_true
  end
end

describe "board" do
  before :each do
    @board = Board.new
  end
  it "should be populated with referencable cells in 2 dimensions" do
    @board[0,0].should be_a_kind_of Cell
  end
  it "should store cells live status" do
    @board[0,0].live!
    @board[0,0].alive?.should be_true
  end

  it "should store a different cell" do
    @board[1,1].live!
    @board[1,1].alive?.should be_true
  end

  it "should store a negative cell" do
    @board[-1,-1].live!
    @board[-1,-1].alive?.should be_true
  end

  it "should know the number of live neighbours of a given cell" do
    @board = Board.new [[0,1],
                        [1,1]]
    @board.neighbours_of(0,0).select(&:alive?).length.should be 3
  end
end
describe "array renderer" do
  it "should render to an array" do
    @game = Game.new
    @game.renderer = ArrayRenderer.new
    @game.board[-1,-1].live!
    @game.board[-1, 1].live!
    @game.board[ 1, 1].live!
    @game.board[ 1,-1].live!
    @game.board[ 0, 0].live!
    @game.render.should == [[1,0,1],
                            [0,1,0],
                            [1,0,1]]
  end
end

describe "text renderer" do
  before :each do
     @renderer = TextRenderer.new(3,3)
     @renderer.living = '#'
     @renderer.dead = ' '
     @game = Game.new
     @game.renderer = @renderer
  end
  it "should render to text" do
    @game.board[-1,-1].live!
    @game.board[-1, 1].live!
    @game.board[ 1, 1].live!
    @game.board[ 1,-1].live!
    @game.board[ 0, 0].live!
    @game.render.should == "# #\n # \n# #"
  end

  it "should render to text" do
    @game.board[0,0].live!
    @game.render.should == "   \n # \n   "
  end

  it "should render nonsquare properly" do
    @renderer.height = 5
    @game.board[-1,-2].live!
    @game.render.should == "#  \n   \n   \n   \n   "
  end

  it "should render even box properly" do
    @renderer.height = 2
    @renderer.width = 2
    @game.board[0,0].live!
    @game.render.should == "# \n  "
  end

  it "should know how wide the terminal is" do
    @renderer = TextRenderer.new
    @renderer.width.should be > 10
    @renderer.height.should be > 10
  end
end
describe "game" do
  before :each do
    @game = Game.new
  end
  it "should begin with a Board" do
    @game.board.should be_a_kind_of Board
  end
  it "should be seedable" do
    @game.seed! [[0,1,1],
                 [0,0,1],
                 [0,1,0]]
    @game.board[0,0].alive?.should be_false
    @game.board[1,0].alive?.should be_true
    @game.board[2,0].alive?.should be_true
    @game.board[0,1].alive?.should be_false
    @game.board[1,1].alive?.should be_false
    @game.board[2,1].alive?.should be_true
    @game.board[0,2].alive?.should be_false
    @game.board[1,2].alive?.should be_true
    @game.board[2,2].alive?.should be_false
  end

  it "should start at the very beginning" do
    @game.generation.should be 0
  end

  it "should advance generationally" do
    @game.advance!
    @game.generation.should be 1
    @game.advance!
    @game.generation.should be 2
  end
  it "should advance the board according to the rules of cell life" do
    @game.seed! [[1,1,1]]
    @game.advance!
    @game.board[0,0].alive?.should be_false
    @game.board[1,0].alive?.should be_true
    @game.board[2,0].alive?.should be_false
    @game.board[1,1].alive?.should be_true
    @game.board[1,-1].alive?.should be_true
  end
end
