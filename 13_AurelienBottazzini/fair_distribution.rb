=begin
Original problem  url: http://rubylearning.com/blog/2010/01/26/rpcfn-fair-distribution-6/

The goal of this class is to schedule printing jobs between printing machines (presses)

  Jobs should be distributed "in such a manner that (a) all t-shirts are printed in the least amount of time,
 and (b) the distribution of work across machines is as fair as possible (i.e. the standard deviation
 of the time each machine spends working is minimized)."

Usage:
 jobs = [5,5,4,4,3,3,3]
 number_of_presses = 3

 fd = FairDistribution.new(jobs, number_of_presses)
 fd.time_required
 fd.distribution

Note:
Class ensure that jobs is an array containing only positive numeric
Class ensure that number_of_presses is valid (positive and an integer)

tested with ruby 1.8.6-p388, 1.8.7-p249 and 1.9.1-p378
=end
class FairDistribution

  attr_accessor :distribution, :time_required

  def initialize jobs, number_of_presses

    if number_of_presses.integer? == false || number_of_presses < 1
      raise ArgumentError, "The number of presses needs to be an integer greater or equal to 1"
    end

    if jobs.is_a?(Array) == false
      raise ArgumentError, "jobs should be an array containing positive numeric"
    end

    jobs.each do |job|
      if job.is_a?(Numeric) == false || job < 0
        raise ArgumentError, "All Jobs should be positive numeric"
      end
    end

    @number_of_presses = number_of_presses

    # starting with the highest time possible (sum of all jobs)
    @time_required = jobs.inject(0.0) { |sum, n| sum + n }

    # will hold signatures of tested distributions (so that we don't
    # try to compute equivalent distribution)
    @signatures = Hash.new

    # initializing an empty distribution with the correct number of presses
    @distribution = []
    number_of_presses.times { @distribution << Array.new }

    # sets @time_required and @distribution
    distribute_jobs [[]], jobs.dup
  end


  private

  # Recusive procedure
  # It should be called initially with a list of jobs and an empty
  # distribution containing one empty press ( = [[]]).
  # It will try to find the optimal distribution and store it in
  # @distribution. It will also store the time required by this
  # optimal distribution in @time_required.
  def distribute_jobs distrib, jobs

    # we can stop, we have reached the maximum number of press
    if distrib.size == @number_of_presses

      # copy the remaining jobs in last press and empty jobs array
      while !jobs.empty?
        distrib.last << jobs.pop
      end

      # we don't have any solution yet, copy this one
      if FairDistribution.is_distribution_empty?(@distribution)
        @distribution = distrib
        # let's check if this distribution is better than our previous
        # best and make it the new solution if it is
      elsif FairDistribution.time_required(distrib) <= @time_required &&
          FairDistribution.standard_deviation(distrib) < FairDistribution.standard_deviation(@distribution)
        @distribution = distrib
        @time_required = FairDistribution.time_required(@distribution)
      end

      return
    end

    # create a signature for this distribution so that we don't test
    # equivalent distributions.
    # ex: [[5, 4], [5, 4], [3, 3, 3]] and  [[4, 5], [5, 4], [3, 3, 3]]
    #   are equivalent and only one of them needs to be tested.
    signature = String.new
    distrib.each_with_index {|e, index| distrib[index] = e.sort }
    distrib.sort {|a,b| a.inject(0.0) { |sum, n| sum + n } <=> b.inject(0.0) { |sum, n| sum + n } }.each do |press|
      press.each { |job| signature << "#{job};" }
      signature << "|"
    end

    # have we tried yet this distribution?
    if @signatures.key?(signature) == false

      # we have exceeded the @time_required of our current best
      # distribution, we don't need to test this distribution
      if FairDistribution.time_required(distrib) <= @time_required
        # mark this distribution has tried
        @signatures[signature] = 1

        jobs.each_with_index do |job, index|

          # we create two new distributions
          # First one : we add one job in last press
          # Second one: we add one job in last press and we add one
          # more press
          distrib_copy =  FairDistribution.dup_distrib(distrib)
          distrib_copy.last << job
          distrib_copy2 = FairDistribution.dup_distrib(distrib_copy)
          distrib_copy2 << Array.new

          # copying remaining jobs list and removing the job we added
          # in the two new distributions
          jobs_copy = jobs.dup
          jobs_copy.slice!(index)

          distribute_jobs distrib_copy, jobs_copy
          distribute_jobs distrib_copy2, jobs_copy.dup
        end
      end
    end
  end

  def self.dup_distrib distrib

    new_distrib = Array.new
    distrib.each do |d|
      new_distrib << d.dup
    end

    return new_distrib
  end

  def self.standard_deviation distrib

    sums = Array.new
    distrib.each do |d|
      sums << d.inject(0.0) { |sum, n| sum + n }
    end

    mean = sums.inject(0.0) { |sum, n| sum + n } / distrib.size
    variance = sums.inject(0.0) {|sum, n| sum + (n - mean) * (n - mean) } / distrib.size
    return Math.sqrt(variance)
  end

  def self.time_required distrib

    time_required = 0.0
    if distrib != nil
      distrib.each do |d|
        d_time_required = d.inject(0) { |sum, n| sum + n }
        if  d_time_required > time_required
          time_required = d_time_required
        end
      end
    end

    return time_required
  end

  # empty meaning distribution containing no press or presses
  # but without any jobs
  def self.is_distribution_empty? distrib
    is_empty = true

    distrib.each do |d|
      if d.size > 0
        is_empty = false
        break
      end
    end

    return is_empty
  end

end
