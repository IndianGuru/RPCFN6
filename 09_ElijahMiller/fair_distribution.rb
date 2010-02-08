# http://rubylearning.com/blog/2010/01/26/rpcfn-fair-distribution-6/

module Enumerable
  def sum
    inject(0) { |acc, v| acc + v }
  end
end

class FairDistribution
  attr_accessor :jobs, :worker_count, :distribution
  
  def initialize(jobs, worker_count)
    self.jobs = jobs
    self.worker_count = worker_count
    self.distribution = (1..worker_count).map { [] }
    distribute
  end
  
  def distribute
    todo = jobs.dup.sort
    i = 0
    while largest = todo.pop
      log "round #{i += 1 } (remaining #{todo.inspect})"
      shortest_worker = distribution.sort { |a, b| a.sum <=> b.sum }.first
      shortest_worker << largest
      print_distribution
    end

    loop do
      log "settling round #{i += 1 }"
      distribution.each { |w| w.sort! }
      sorted_distribution = distribution.sort { |a, b| a.sum <=> b.sum }
      sorted_distribution = sorted_distribution.map { |w| w.dup }

      largest = sorted_distribution.first.shift
      smallest = sorted_distribution.last.pop
      sorted_distribution.first << smallest
      sorted_distribution.last << largest

      if sorted_distribution.map { |w| w.sum }.max > time_required
        log "settling round produced slower distribution"
        break
      end
      self.distribution = sorted_distribution
      print_distribution
    end
    log
    print_distribution
  end
  
  def print_distribution
    log distribution.map { |w| "  %3s = #{w.inspect}" % w.sum.to_s }.join("\n")
  end
  
  def time_required
    distribution.map { |w| w.sum }.max
  end
  
  def log(*args)
    # puts *args
  end
  
end
