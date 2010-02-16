require 'test/unit'
require 'fair_distribution'

#FairDistribution = LowMemoryFairDistribution

class FairQueueTest < Test::Unit::TestCase
  
  def test_basic1
    jobs              = [10, 15, 20, 24, 30, 45, 75]
    number_of_presses = 2

    exp_max           = 110

    fd = FairDistribution.new(jobs, number_of_presses)
    assert_equal exp_max, fd.time_required

    # A Solution
    #     [75, 20, 15],
    #     [45, 30, 24, 10,]
  end

  def test_basic2
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

  def test_basic3
    jobs              = [0.23, 0.47, 0.73, 1.5, 3.0, 3.2, 1.75, 2.3, 0.11, 0.27, 1.09]
    number_of_presses = 4

    exp_max           = 3.73

    fd = FairDistribution.new(jobs, number_of_presses)
    assert_equal exp_max, fd.time_required

    # A Solution
    #     [3.2, 0.47],
    #     [3.0, 0.73],
    #     [2.3, 1.09, 0.23],
    #     [1.75, 1.5, 0.27, 0.11]
  end if ARGV[0] == "full" # only use this TC if 'full' is added as an argument.

  def test_basic4
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

  def test_basic5
    fd = FairDistribution.new([0.23, 0.47, 0.73, 1.5, 3.0, 3.2], 4)
    assert_equal 3.2, fd.time_required
    assert_distributions_are_equivalent [[3.0], [3.2], [0.23, 0.47, 0.73], [1.5]], fd.distribution
  end

  def test_basic6
    jobs = [5,5,4,4,3,3,3,1,1,1]
    number_of_presses = 3

    exp_max = 10
    fd = FairDistribution.new(jobs, number_of_presses)
    assert_equal exp_max, fd.time_required
  end

  def test_basic7
    jobs = [10,10,1,1,1,1,1,1]
    number_of_presses = 3

    exp_max = 10
    exp_distribution = [
                        [10],
                        [10],
                        [1,1,1,1,1,1],
                       ]
    fd = FairDistribution.new(jobs, number_of_presses)
    assert_equal exp_max, fd.time_required
  end

  def test_empty_jobs
    jobs = []
    number_of_presses = 2
      
    fd = FairDistribution.new(jobs, number_of_presses)
    assert_equal 0.0 , fd.time_required
    assert_distributions_are_equivalent [[],[]], fd.distribution

    number_of_presses = 1
    fd = FairDistribution.new(jobs, number_of_presses)
    assert_distributions_are_equivalent [[]], fd.distribution
  end

  def test_zero_press
    jobs = [1,2,3,4,5,6]
    number_of_presses = 0

    assert_raise(ArgumentError) { FairDistribution.new(jobs, number_of_presses) }
  end

  def test_float_number_of_press
    jobs = [3,4,5,6,7,8]
    number_of_presses = 2.3

    assert_raise(ArgumentError) { FairDistribution.new(jobs, number_of_presses) }
  end

  def test_bad_jobs
    jobs = ["dscscds", 1, 2.3]
    number_of_presses = 3

    assert_raise(ArgumentError) { FairDistribution.new(jobs, number_of_presses)}

    jobs = [5, 2, -3]
    assert_raise(ArgumentError) { FairDistribution.new(jobs, number_of_presses)}

    jobs = "wrong"
    assert_raise(ArgumentError) { FairDistribution.new(jobs, number_of_presses)}
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
