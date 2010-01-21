class Array
  def min_index
    _min       = first
    _min_index = 0
    each_with_index do |elem, index|
      if elem < _min
        _min = elem 
        _min_index = index
      end
    end
    _min_index
  end
  
  def max
    _max = first
    each do |elem|
      _max = elem if elem > _max
    end
    _max
  end
  
  def sum
    inject(0) {|total, elem| total + elem}
  end
end

class QuickDistribution
  def initialize(durations, queues)
    @durations = durations
    @queues    = queues
  end
  
  def distribution
    ret_queues = Array.new(@queues) {[]}
    sorted = @durations.sort {|a, b| b <=> a }
    sorted.each do |val|
      place_in_lightest_queue(val, ret_queues)
    end
    ret_queues
  end
  
  def time_required
    distribution.map{|q| q.sum}.max
  end
  
  private
    def place_in_lightest_queue(val, queues)
      sums = queues.map {|queue| queue.sum}
      min_index = sums.min_index
      queues[min_index] << val
    end
end

class FairDistribution
  def initialize(durations, queues)
    @durations = durations
    @queues    = queues
  end
  
  def distribution
    args = (0..(@durations.size-1)).map {|i| (0..(@queues-1)).to_a}
    all_possible_distributions = cartesian_product(*args)

    _min = @durations.sum
    _sd  = -1
    _ret = nil
    
    all_possible_distributions.each do |distribution_by_queue_num|
      this_dist = translate_distribution_by_queue_num(distribution_by_queue_num)
      this_max  = max_sum(this_dist)
      this_sd   = stdev(this_dist)
      if this_max == _min && this_sd < _sd
        _ret  = this_dist
        _sd   = this_sd
      end
      if this_max < _min
        _min = this_max
        _ret = this_dist
        _sd  = this_sd
      end
    end
    _ret
  end
  
  def time_required
    max_sum(distribution)
  end
  
  private
    def translate_distribution_by_queue_num(distribution_by_queue_num)
      this_dist = Array.new(@queues) {[]}
      distribution_by_queue_num.each_with_index do |queue_index, job_index|
        this_dist[queue_index] << @durations[job_index]
      end
      this_dist
    end
    
    # e.g. cartesian_product([1,2,3,4], [1,2,3,4], [1,2,3,4])
    def cartesian_product(*arrays)
      result = [[]]
      while [] != arrays
        t, result = result, []
        b, *arrays = arrays
        t.each do |a|
          b.each do |n|
            result << a + [n]
          end
        end
      end
      result
    end
    
    def max_sum(a_distribution)
      a_distribution.map{|q| q.sum}.max
    end
    
    def stdev(a_distribution)
      sums = a_distribution.map{|q| q.sum}
      count = sums.size
      mean = sums.sum / count.to_f
      stddev = Math.sqrt( sums.inject(0) { |sum, e| sum + (e - mean) ** 2 } / count.to_f )
    end
end

class LowMemoryFairDistribution
  def initialize(durations, queues)
    @durations = durations
    @queues    = queues
  end
  
  def distribution
    _min = @durations.sum
    _ret = nil
    
    each_distribution do |dist|
      this_max = max_sum(dist)
      if this_max < _min
        _min = this_max
        _ret = dist
      end
    end
    _ret
  end
  
  def time_required
    max_sum(distribution)
  end
  
  private
    def translate_distribution_by_queue_num(distribution_by_queue_num)
      this_dist = Array.new(@queues) {[]}
      distribution_by_queue_num.each_with_index do |queue_index, job_index|
        this_dist[queue_index] << @durations[job_index]
      end
      this_dist
    end
    
    def each_distribution(&block)
      each_cartesian_product do |dist|
        yield(translate_distribution_by_queue_num(dist))
      end
    end
    
    def each_cartesian_product(&block)
      number_of_solutions = @queues**(@durations.size)
      (0..(number_of_solutions - 1)).each do |sln_number|
        distribution = sln_number.to_s(@queues).rjust(@durations.size, "0").split("").map {|ch| ch.to_i}
        yield(distribution)
      end
    end
    
    def max_sum(a_distribution)
      a_distribution.map{|q| q.sum}.max
    end
end