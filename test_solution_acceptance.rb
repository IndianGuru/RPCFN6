require 'test/unit'
require 'fair_distribution'

class FairQueueTest < Test::Unit::TestCase
  
  def test_basic1
    jobs              = [1.0, 4.75, 2.83, 1.1, 5.8, 3.5, 4.4]
    number_of_presses = 4
    
    exp_max           = 6.33
    exp_distribution  = [
        [1.0, 4.75],
        [2.83, 3.5],
        [1.1, 4.4], 
        [5.8]
      ]
      
    fd = FairDistribution.new(jobs, number_of_presses)
    assert_equal exp_max, fd.time_required
    assert_distributions_are_equivalent exp_distribution, fd.distribution
  end
  
  # def test_basic2
  #   jobs              = [14.0, 0.23, 0.47, 0.73, 1.5, 3.0, 3.2, 1.75, 9.8, 6.1, 2.3, 4.2, 0.11, 0.27, 6.14, 1.09, 3.12]
  #   number_of_presses = 5
  #   
  #   exp_max           = 14.0
  #   exp_distribution  = [
  #       [0.23, 1.09, 2.3, 3.2, 4.2],
  #       [0.27, 1.5, 3.12, 6.1],
  #       [0.11, 1.75, 3.0, 6.14],
  #       [0.47, 0.73, 9.8],
  #       [14.0]
  #     ]
  #     
  #   fd = FairDistribution.new(jobs, number_of_presses)
  #   assert_equal exp_max, fd.time_required
  #   assert_distributions_are_equivalent exp_distribution, fd.distribution
  # end
  
  def test_basic3
    jobs              = [10, 15, 20, 25, 30, 45, 75]
    number_of_presses = 2
    
    exp_max           = 110
    exp_distribution  = [
        [75, 25, 10],
        [45, 30, 20, 15]
      ]
      
    fd = FairDistribution.new(jobs, number_of_presses)
    assert_equal exp_max, fd.time_required
    assert_distributions_are_equivalent exp_distribution, fd.distribution
  end
  
  # def test_basic4
  #   jobs              = [0.5, 1.45, 0.32, 1.72, 0.89, 1.14, 2.35, 1.09, 0.87, 0.79, 0.14, 1.23, 1.24, 1.19, 0.44, 0.32, 1.14, 1.83, 0.45, 0.24, 1.52]
  #   number_of_presses = 4
  #   
  #   exp_max           = 5.23
  #   exp_distribution  = [
  #       [2.35, 1.19, 0.89, 0.45, 0.32], 
  #       [1.83, 1.23, 1.09, 0.5, 0.44, 0.14], 
  #       [1.72, 1.24, 1.14, 0.87, 0.24], 
  #       [1.52, 1.45, 1.14, 0.79, 0.32]
  #     ]
  #     
  #   fd = FairDistribution.new(jobs, number_of_presses)
  #   assert_equal exp_max, fd.time_required
  #   assert_distributions_are_equivalent exp_distribution, fd.distribution
  # end
  
  def test_basic5
    jobs = [5,5,4,4,3,3,3]
    number_of_presses = 3
  
    exp_max = 9
    exp_distribution = [
      [5,4],
      [5,4],
      [3,3,3],
    ]
    fd = FairDistribution.new(jobs, number_of_presses)
    assert_equal exp_max, fd.time_required
    assert_distributions_are_equivalent exp_distribution, fd.distribution
  end
  
  # Testing Implementation
  # def test_arrays_have_same_elements
  #   assert arrays_have_same_elements?([1,2,3], [3,1,2])
  #   assert !arrays_have_same_elements?([], [1,2,3])
  #   assert !arrays_have_same_elements?([1,2,3], [1,2,3,4])
  #   assert !arrays_have_same_elements?([1,2,3,4], [1,2,3])
  #   assert !arrays_have_same_elements?([1,1], [1])
  #   assert !arrays_have_same_elements?([1], [1,1])
  # end
  # 
  # def test_distributions_are_equivalent
  #   assert distributions_are_equivalent?([[1, 2], [2, 3]], [[3, 2], [2, 1]])
  #   assert !distributions_are_equivalent?([[1, 3], [2, 2]], [[3, 2], [2, 1]])
  #   assert !distributions_are_equivalent?([[1, 2], [3, 2]], [[3, 2], [3, 2]])
  #   assert !distributions_are_equivalent?([[1, 2], [1, 2]], [[3, 2], [2, 1]])
  # end
  
  private
    def assert_distributions_are_equivalent(dist1, dist2, msg=nil)
      failure_message = "Distributions not equivalent: #{msg}: #{dist1.inspect} not equivalent to #{dist2.inspect}"
      assert(distributions_are_equivalent?(dist1, dist2), failure_message)
    end
  
    def distributions_are_equivalent?(dist1, dist2)
      return false if dist1.size != dist2.size
      my_dist1 = dist1.dup
      my_dist2 = dist2.dup
      
      my_dist1.reject! {|queue1|
        dist2.detect {|queue2| arrays_have_same_elements?(queue1, queue2)}
      }
      
      my_dist2.reject! {|queue2|
        dist1.detect {|queue1| arrays_have_same_elements?(queue1, queue2)}
      }
      
      my_dist1.empty? && my_dist2.empty?
    end
    
    def arrays_have_same_elements?(arr1, arr2)
      arr1.size == arr2.size && (arr1 - arr2).empty?
    end
end