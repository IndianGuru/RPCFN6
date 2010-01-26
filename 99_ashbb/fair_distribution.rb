# ashbb's solution for RPCFN6
class FairDistribution
  attr_reader :distribution
  
  def initialize jobs, n
    @jobs, @n= jobs, n
    max = jobs.inject(:+)
    @solution = [max, max]
  end
  
  def time_required
    100000.times do |i|
      random_candidate
      time = @candidate.collect{|press| press.inject(:+)}.max
      score = @candidate.collect{|press| time - press.inject(:+)}.max
      if time <= @solution[0] and score < @solution[1]
        @solution = []
        @solution << time << score << @candidate
      end
    end
    @distribution = @solution[2].collect{|e| e - [0]}
    p @solution[0], @distribution  # debug
    @solution[0]
  end
  
  def random_candidate
    @candidate = Array.new(@n){[0]}
    @jobs.each do |job|
      @candidate[rand @n] << job
    end
  end
end

=begin
jobs = [0.23, 0.47, 0.73]
number_of_presses = 4

fd = FairDistribution.new(jobs, number_of_presses)
p fd.time_required
p fd.distribution
=end
