# Adam Lum's solution to RPCFN #6
# http://rubylearning.com/blog/2010/01/26/rpcfn-fair-distribution-6/

# Definitely not the most elegant, efficient,  or Computer Science-y
# way to handle this challenge, but it's _a_ solution to these small sets.
# (For the sake of my code, hopefully the hypothetical t-shirt printing 
# company in the problem never owns more than 4 machines) :)

class FairDistribution
  
  attr_accessor :number_of_presses, :jobs, :cached_time_required, :cached_distribution
  
  def initialize(in_jobs, in_number_of_presses)
    @number_of_presses    = in_number_of_presses
    @jobs                 = in_jobs
    @cached_time_required = nil # So the calculation doesn't have to run more than once
    @cached_distribution  = nil # So the calculation doesn't have to run more than once
  end
  
  def time_required
    if (@cached_time_required == nil)
      calculate
    end
    @cached_time_required
  end
  
  def distribution
    if (@cached_distribution == nil)
      calculate
    end
    @cached_distribution
  end
  
  def partition_set(in_set)
    total_sum             = array_sum(in_set)
    index_array           = []
    subsets               = []
    partitioned_set       = []
    partition_difference  = 1 << 64
    (0..in_set.size - 1).each do |p|
      index_array << p
    end
    (1..in_set.size).each do |i|
      index_array.combination(i).each do |c|
        subsets << c
      end
    end
    subsets.each do |s|
      subset_sum            = subset_sum(s, in_set)
      difference_subset_sum = subset_sum(index_array - s, in_set)
      if (subset_sum + difference_subset_sum == total_sum && (subset_sum - difference_subset_sum).abs < partition_difference)
        partitioned_set = [s, index_array - s]
        partition_difference = (subset_sum - difference_subset_sum).abs
      end
    end
    (0..1).each do |i|
      temp_array = []
      partitioned_set[i].each do |j|
        temp_array << in_set[j]
      end
      partitioned_set[i] = temp_array
    end
    partitioned_set
  end
  
  def three_partition
    total_sum             = array_sum(@jobs)
    index_array           = [] 
    subsets               = []
    possible_distribution = []
    partition_difference  = 1 << 64
    (0..jobs.size - 1).each do |p|
      index_array << p
    end
    (1..@jobs.size).each do |i|
      index_array.combination(i).each do |c|
        subsets << c
      end
    end
    subsets.each do |s|
      (0..subsets.size - 1).each do |i|
        (0..subsets.size - 1).each do |j|
          if ((s + subsets[i] + subsets[j]).sort! == index_array)
            partition1_sum = subset_sum(s, @jobs)
            partition2_sum = subset_sum(subsets[i], @jobs)
            partition3_sum = subset_sum(subsets[j], @jobs)
            if ((partition1_sum + partition2_sum + partition3_sum) == total_sum)
              partition_difference_array = []
              partition_difference_array << (partition1_sum - partition2_sum).abs
              partition_difference_array << (partition1_sum - partition3_sum).abs
              partition_difference_array << (partition2_sum - partition3_sum).abs
              partition_difference_array.sort!
              if (partition_difference_array.last < partition_difference)
                possible_distribution = [s, subsets[i], subsets[j]]
                partition_difference = partition_difference_array.last
              end
            end
          end
        end
      end
    end
    return_array = []
    possible_distribution.each do |d|
      partition = []
      d.each do |e|
        partition << @jobs[e]
      end
      return_array << partition
    end
    return_array
  end
  
  def calculate
    if (@number_of_presses == 1)
      @cached_distribution = @jobs
      @cached_time_required = array_sum(@jobs)
    elsif (@number_of_presses == 2)
      @cached_distribution = partition_set(@jobs)
      @cached_time_required = (array_sum(@cached_distribution[0]) > array_sum(@cached_distribution[1])) ? array_sum(@cached_distribution[0]) : array_sum(@cached_distribution[1])
    elsif (@number_of_presses == 3)
      @cached_distribution = three_partition
      time_array = []
      @cached_distribution.each do |c|
        time_array << array_sum(c)
      end
      @cached_time_required = time_array.sort!.last
    elsif (@number_of_presses == 4)
      standard_deviation_value = 1 << 64 # Some large starting value
      (0..20).each do 
        # Shuffling the input array 20 times seemed enough for these small
        # datasets, but test_basic3 in the test_suite still fails sometimes
        # (but it's close)
        @jobs.shuffle!
        first_partition = partition_set(@jobs)
        temp_distribution = partition_set(first_partition[0]) + partition_set(first_partition[1])
        #@cached_distribution = partition_set(first_partition[0]) + partition_set(first_partition[1])
        time_array = []
        temp_distribution.each do |c|
          time_array << array_sum(c)
        end
        time_array.sort!
        if (@cached_time_required == nil || (time_array.last <= @cached_time_required && standard_deviation_value > standard_deviation(time_array)))
          @cached_distribution = temp_distribution
          @cached_time_required = time_array.last
          standard_deviation_value = standard_deviation(time_array)
        end
      end
    else
      @cached_time_required = 0
      @cached_distribution  = []
    end
    @cached_time_required
  end
  
  # Some helper functions
  
  def subset_sum(subset, entire_set)
    # Sums the set of array indexes, based on the entire set 
    return_sum = 0
    subset.each do |i|
      return_sum += entire_set[i]
    end
    return_sum
  end
  
  def array_sum(array_to_sum)
    # Sums the array elements
    return_sum = 0
    array_to_sum.each do |x|
      return_sum += x
    end
    return_sum
  end
  
  def standard_deviation(values)
    count = values.size
    mean = values.inject(:+) / count.to_f
    stddev = Math.sqrt( values.inject(0) { |sum, e| sum + (e - mean) ** 2 } / count.to_f )
  end
  
end