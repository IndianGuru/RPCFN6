## This is an approximation algorithm
## Sort the jobs, then start processing on the processor which has the least amount of jobs scheduled
## Provably the max time is (1/processors * (sum of processes) + max process time) if we do the smallest job first 
## and if we do Longest time first it is 3/2 approximation
## I am doing Longest here first as this will pass most of tests, of course not all

class FairDistribution
  def initialize(jobs, number_of_processes)
    @jobs = jobs.sort
    @number_of_processes = number_of_processes
    @max_sum = @jobs.inject(0) {|sum, i| sum + i}
  end
  
  def time_required
    solve.first
  end
  
  def distribution
    solve.last
  end
  
  def solve
    jobs = Array.new(@jobs)
    distribution = []
    @number_of_processes.times do 
      distribution << [jobs.shift]
    end

    while !jobs.empty?
      index = find_least_end_time_index(distribution)
      distribution[index] += [jobs.shift]
    end
    return find_max_end_time(distribution), distribution
  end
  
  def get_sum_array(distribution)
    sum = []
    distribution.each do |processor|
      sum += [processor.inject(0) {|sum, i| sum + i}]
    end
    sum
  end
  
  def find_max_end_time(distribution)
    sum = get_sum_array(distribution)
    sum.sort.last
  end
  
  def find_least_end_time_index(distribution)
    sum_arr = get_sum_array(distribution)
    min_sum = @max_sum
    index = 0
    min_index = -1
    
    sum_arr.each do |sum|
      if sum < min_sum
        min_index = index
        min_sum = sum
      end
      index+=1
    end
    
    min_index
  end
end