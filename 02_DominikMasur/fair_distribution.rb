class FairDistribution
  def initialize jobs, number_of_presses
    @jobs = jobs
    @number_of_presses = number_of_presses
  end
  def time_required
    max_distribution_length distribution
  end
  def distribution
    return @distribution if @distribution
    @jobs.sort!
    @distribution = []
    @number_of_presses.times do |i|
      @distribution[i] = [@jobs.pop] unless @jobs.empty?
    end
    while !@jobs.empty? do
      @distribution = sort_distributions @distribution
      @distribution.first << @jobs.pop
    end
    old_distribution_length = 0
    while max_distribution_length(@distribution) != old_distribution_length
      old_distribution_length = max_distribution_length(@distribution)
      @distribution = make_it_better @distribution
    end
    return @distribution
  end
  private
    def max_distribution_length distribution
      distribution_length sort_distributions(distribution).last
    end
    # try to improve heavy press with light press after sorting
    def make_it_better distribution
      distribution = sort_distributions distribution
      heaviest_press_jobs = distribution.last.clone
      lightest_press_jobs = distribution.first.clone
      old_heavy_load = distribution_length heaviest_press_jobs
      heaviest_press_jobs.each do |heavy_job|
        lightest_press_jobs.each do |light_job|
          if !(heavy_job == light_job) && !(light_job > heavy_job)
            new_heaviest_press_jobs, new_lightest_press_jobs = change_jobs heaviest_press_jobs.clone, lightest_press_jobs.clone, heavy_job, light_job
            heavy_load = distribution_length(new_heaviest_press_jobs)
            light_load = distribution_length(new_lightest_press_jobs)
            # if there is a better solution then change the values
            if heavy_load < old_heavy_load && light_load < old_heavy_load
              heaviest_press_jobs = distribution.last
              lightest_press_jobs = distribution.first
              heaviest_press_jobs, lightest_press_jobs = change_jobs distribution.last, distribution.first, heavy_job, light_job
              return distribution
            end
          end
        end
      end
      return distribution
    end
    def change_jobs press1, press2, job1, job2
      press1.slice! press1.index(job1)
      press2.slice! press2.index(job2)
      press1 << job2
      press2 << job1
      return press1, press2
    end
    def sort_distributions global_distribution
      global_distribution.sort{|a,b|distribution_length(a) <=> distribution_length(b)}
    end
    def distribution_length my_distribution
      time = 0
      my_distribution.flatten.each {|dist_time| time += dist_time}
      return time
    end
end