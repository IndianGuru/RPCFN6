# RPCFN6: Fair Distribution
# Benoit Daloze
#
# I used some random strategy to keep things really fast, with a simple algorythm of adding a job in the Press with the less time
# Enjoy :)

# Let's add some more 'literal' methods to Array. That is easier(and lighter) to maintain than creating classes.
class Array
  def sum
    self.inject(:+)
  end
  
  def average
    sum.to_f / length
  end
  
  def standard_deviation
    Math.sqrt( 1.0/length * ( map { |x_i| x_i**2 }.sum ) - average**2 )
  end
  
  # time of:
  # - a Distribution = the maximum time needed by a press
  # - a Press = The sum of the times of the jobs
  def time
    @time ||= begin
      if Array === first # Distribution
        times.max
      else # Press
        sum
      end
    end
  end
  
  # Distribution methods
  def times
    map { |press| press.time }
  end
end

class FairDistribution
  def initialize(jobs, presses)
    @jobs, @presses = jobs, presses
  end
  
  def time_required
    distribution.time
  end
  
  def distribution
    @distribution ||= begin
      # We got here many ways, because I'm simply adding a job in the Press that takes the less time
      
      # 1) Sure way, far too long
      # jobs_sets = @jobs.permutation # len! test3(11) => 39 916 800
      
      # 2) Very fast way, but doesn't work for test_basic4
      # jobs_sets = [
      #   @jobs,
      #   @jobs.sort,
      #   @jobs.sort.reverse
      # ]
      
      # 3) Cool&Fast way, solve all(100%) with **4(in 1.1s) and often(92%) with **3(in 0.1s)
      # 97/100 with **3.3(in 0.2s !)
      jobs_sets = (@jobs.length**3.3).to_i.times.map { @jobs.shuffle }
      
      bad_distribution = [ Array.new(@presses, [@jobs.sum]) ]
      
      jobs_sets.inject(bad_distribution) { |good_dists, jobs|
        # First choice: the less time for the distribution
        dist = jobs.each_with_object( Array.new(@presses) { [] } ) { |job, presses|
          presses.min_by { |p| p.sum or 0 } << job # We add the job to the Press that takes (currently) the less time
        }
        max, best = dist.time, good_dists.first.time
        
        # Some optimisation: keep only the best time(s)
        if max < best # We want to keep the fastest, and drop the others
          [dist]
        elsif max == best # Another good candidate: we add it
          good_dists << dist
        else # A slower Distribution, we discard it
          good_dists
        end
      }.min_by { |presses|
        # Second choice: minimal standard deviation of times of each Press of the Distribution
        presses.times.standard_deviation
      }
    end
  end
end

if __FILE__ == $0
  jobs              = [10, 15, 20, 24, 30, 45, 75]
  number_of_presses = 2
  exp_max           = 110
  fd = FairDistribution.new(jobs, number_of_presses)
  p "#{fd.time_required} must be #{exp_max}"
  p fd.distribution
end