# Author : Guillaume Petit

class Array
  
  def sum
    inject(0.0) { |memo, value| memo + value }
  end
  
end

class FairDistribution
  
  attr_reader :distribution
  
  def initialize(jobs, nb_of_presses)
    @jobs = jobs.sort { |a, b| b <=> a }
    @nb_of_presses = nb_of_presses
    
    @ideal_balance = @jobs.sum / @nb_of_presses
    
    balance # the real deal
  end
  
  def time_required
    @distribution.map { |distrib| distrib.sum }.max
  end
  
  private
  
  def balance
    @distribution = (1..@nb_of_presses).map { [] }
    
    @jobs.each do |job|
      @distribution[find_place_for(job)] << job
    end
  end
  
  # try to find a place (distribution) by first looking for an "ideal" place
  # and if not found, use the smallest simulated time
  def find_place_for(job)
    simulated_times = @distribution.map { |distrib| distrib.sum + job }
    simulated_times.index(@ideal_balance) || simulated_times.each_with_index.min.last
  end
  
end