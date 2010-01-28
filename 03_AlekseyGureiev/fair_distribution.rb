require '03_AlekseyGureiev/utils'  # edited for unit test by ashbb
require '03_AlekseyGureiev/swap'   # edited for unit test by ashbb

# A very simple algorithm based on incremental balancing of job queues.
# Initially, the first queue has all the jobs that are gradually distributed
# across available queues. The algorithm doesn't take much memory since it
# does not involve the recursive traversing of the options tree and
# doesn't store lots of intermediate data.
class FairDistribution
  
  def initialize(jobs, num_of_queues)
    @queues = [ jobs.sort.reverse ]
    (num_of_queues - 1).times { @queues << [] }

    # Balance the queues until they are perfectly balanced
    while !balance_all_queues do; end
  end
  
  # Time required for all queues processing
  def time_required
    @queues.map { |q| q.sum }.max
  end
  
  # The actual distribution of jobs across the queues
  def distribution
    @queues
  end
  
  private
  
  # Runs through all queues and balances them against each other.
  # Makes one pass only and returns FALSE if there was nothing changed
  # during the pass.
  def balance_all_queues
    updated = false
    
    @queues.each_with_index do |q1, qi1|
      (qi1+1 ... @queues.size).each do |qi2|
        res = balance_queues(q1, @queues[qi2])
        updated ||= res
      end
    end
    
    return !updated
  end
  
  # Balances the two queues between themselves by finding the best possible
  # swap of jobs between them. If there's nothing to be improved, returns FALSE.
  def balance_queues(q1, q2)
    delta = q1.sum - q2.sum
    return false if delta == 0
    
    best_swap       = nil
    best_swap_delta = delta.abs
          
    q1.each_combination do |c1|
      best_swap, best_swap_delta = choose_better_swap(c1, [], delta, best_swap, best_swap_delta)
    
      q2.each_combination do |c2|
        best_swap, best_swap_delta = choose_better_swap(c1, c2, delta, best_swap, best_swap_delta)
      end
    end
  
    best_swap.apply(q1, q2) unless best_swap.nil?
      
    return !best_swap.nil?
  end
  
  # Sees if the swap we have at hand is better than our current best
  # swap and replaces the latest if it is.
  def choose_better_swap(c1, c2, delta, best_swap, best_swap_delta)
    unless c1 == c2
      s = Swap.new(c1, c2, delta)
      best_swap, best_swap_delta = s, s.delta if s.delta < best_swap_delta 
    end
    
    return best_swap, best_swap_delta
  end
end