#
# generates all possible distributions by splitting job list in distinct non empty subcollections with the help of Array's combination method
# then finds the best (see Array#chunk and FairDistribution#find_best_distribution for detailed explanation)
#
 
class Array
  #
  # returns the sum of all elements
  #
  # note: works best with homogenous numeric collections
  #
  def sum
    inject(:+)
  end
  
  #
  # calls array's combination method for each value in range and passes the block to it
  #
  # note: block must be given, unlike Array#combination
  #
  def combination_with_range(range, &block)
    raise ArgumentError.new('please provide a block') unless block_given?
    range.each do |chunk_size|
      combination(chunk_size, &block)
    end
  end
  
  #
  # deletes each element of items only once in self
  #
  # unlike Array#- that deletes multiple items if eql? is true
  # that is especially bad when dealing with duplicate integer values in a collection, like in this challenge
  #
  def delete_first(items)
    items = [items] unless items.respond_to?(:each)
    items.each do |item|
      delete_at(index(item))
    end
    self
  end
 
  #
  # returns all possible combinations of distinct non empty subcollections that when unioned equal self
  # if more than two subcollections are requested, calls itself recursive on the second chunk
  #
  # huh?
  #
  # computes all subcollections with minimum length of one and maximum length of all elements minus the number of the remaining chunks,
  # so that every chunk can have at least one element
  #
  # that collection forms all possible combinations for the first chunk (order is ignored)
  #
  # for each of those combinations computes the collection of the remaining elements, that is the difference of self and that combination
  # (duplicate items are only removed once per item in the second collection)
  #
  # both collections are combined and form one possible result which gets collected and finally returned
  #
  # if more than two chunks are requested the second subcollection gets recursively chunked in (chunks - 1) chunks
  # the two collections are then combined by prepending the first collection to each element of the second collection
  #
  def chunk(chunks)
    raise ArgumentError.new('please choose at least two chunks') if chunks < 2
    
    results = []
    
    min_chunk_size, max_chunk_size = 1, size - (chunks - 1)
    
    combination_with_range(min_chunk_size..max_chunk_size) do |taken_items|
      remaining_items = dup.delete_first(taken_items)
      
      if chunks == 2
        results << [taken_items, remaining_items]
      else
        remaining_items.chunk(chunks - 1).each do |remaining_piece|
          results << remaining_piece.unshift(taken_items)
        end
      end
    end
    
    results
  end
end
 
class FairDistribution
  def initialize(jobs, number_of_presses)
    @jobs = jobs
    @number_of_presses = number_of_presses
  end
  
  #
  # required time is the time of the slowest press
  #
  def time_required
    @time_required ||= distribution.map(&:sum).max
  end
  
  #
  # returns the distribution considered as best
  #
  def distribution
    @distribution ||= find_best_distribution
  end
  
private
  
  #
  # computes and returns best distribution
  #
  # that is the distribution with the lowest required time
  # if more than one distribution is found, returns the first one with the lowest standard deviation
  #
  # how:
  # gets all possible distributions,
  # for each one it computes the required time and standard deviation if needed,
  # remembers the best, returns the best
  #
  # Array#chunk does the hard work
  #
  def find_best_distribution
    required_time, best_distribution = nil, nil
    
    all_distributions = @jobs.chunk(@number_of_presses)
        
    all_distributions.each do |distribution|
      time_required_by_distribution = distribution.map(&:sum).max
      if required_time.nil? || time_required_by_distribution < required_time
        best_distribution = distribution
        required_time = time_required_by_distribution
      else
        if time_required_by_distribution == required_time
          best_distribution = distribution if standard_deviation(distribution) < standard_deviation(best_distribution)
        end
      end
    end
        
    best_distribution
  end
  
  #
  # returns the standard deviation of the given distribution
  #
  # (thanks for finally making me understand what standard deviation is all about :)
  #
  def standard_deviation(distribution)
    u = distribution.map(&:sum).sum / distribution.size
    Math.sqrt(distribution.map(&:sum).map{|x| (x-u)**2}.sum / distribution.size)
  end
end