require 'test/unit'
require 'swap'

class SwapTest < Test::Unit::TestCase
  
  def test_swap_returns_correct_positive_delta
    current_delta = 10 # q1.sum - q2.sum = 10
    from_q1 = [ 1, 2 ] # 1 + 2 = 3
    from_q2 = [ 3, 4 ] # 3 + 4 = 7
    
    swap = Swap.new(from_q1, from_q2, current_delta)
    assert_equal 10 - 2 * (3 - 7), swap.delta
    
    # We multiply by 2 since we not only take [1, 2] from q1, but also add them to q2
    # which makes the difference twice as big.
  end
  
  def test_swap_returns_correct_negative_delta
    current_delta = 10 # q1.sum - q2.sum = 10
    from_q1 = [ 3, 4 ] # 3 + 4 = 7
    from_q2 = [ 1, 2 ] # 1 + 2 = 3
    
    swap = Swap.new(from_q1, from_q2, current_delta)
    assert_equal 10 - 2 * (7 - 3), swap.delta
  end
  
  def test_applying_changes_should_move_elements_between_queues
    q1 = [ 1, 1, 2 ]
    q2 = [ 3, 4 ]
    
    swap = Swap.new([ 1, 2 ], [ 3 ], -3)
    swap.apply(q1, q2)
    
    assert_equal [ 1, 3 ], q1
    assert_equal [ 4, 1, 2 ], q2
  end
  
end