class Array
  # Ruby shortcut to quickly sum everything.
  # This will obviously break if the elements can't be added together.
  def sum
    self.inject(&:+)
  end
end

class Press < Array
  include Enumerable, Comparable
  attr_accessor :jobs, :time

  def initialize jobs=[], time=0
    @jobs = jobs
    @time = time
  end

  def << *jobs
    @jobs.concat jobs.flatten
    @time += jobs.sum
    self
  end

  def each
    @jobs.each { |job| yield job }
  end

  def <=> other
    @time <=> other.time
  end

  def inspect
    @jobs
  end

  def delete *items
    items.flatten.each do |item|
      if @jobs.include? item
        @jobs.delete item
        @time -= item
      end
    end
    self
  end

  def clear
    @jobs = []
    @time = 0
    self
  end
  
end

class FairDistribution
  attr_reader :time_required, :distribution

  def initialize jobs=[], presses=0
    puts
    throw "Stop the presses! They've been stolen!" if presses.zero?
    @count_of_presses = presses
    @jobs = jobs.sort
    @time_required = 0
    @distribution = []
    mills_mess
    populate_time_and_distribution # Get press queues and longest running time.

  end

  private

  # The hardest three-ball juggling sequence there is!
  def mills_mess
    if @count_of_presses == 1
      press = Press.new
      press << @jobs
      @distribution << press.jobs
      @time_required = press.time
      return
    end

    @presses = Array.new(@count_of_presses) { Press.new }

    @presses.min << @jobs.pop until @jobs.empty?      


  end

  def populate_time_and_distribution
    @presses.each { |press| @distribution << press.jobs }
    @time_required = @presses.max.time
  end

end