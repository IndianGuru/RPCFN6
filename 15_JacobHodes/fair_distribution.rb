# RPCFN Six: Fair Distribution
# Submitted February 20, 2010
# Author: Jacob Hodes <jacob@peashutop.com>

class Array
  
  # Sums the numeric values of a one-dimensional array
  # Non-numeric values add 0 to the running total
  # Examples: [1,2,3,'a'].sum  => 6
  #           ['a',[1,2]].sum  => 0
  #
  def sum
    inject(0) {|total, value| value.is_a?(Numeric) ? total + value : total }
  end
  
  # Returns an array of all possible ways to divide self into num_segs segments
  # This is a combination-style method, i.e. order is not important 
  # Example: [3,4,5].segmentations(2) => [ [[3, 4], [5]], [[3, 5], [4]], [[3], [4, 5]] ]
  #
  def segmentations(num_segs)
    return [[self]] if num_segs == 1
    return [ map { |el| [el] } ] if length == num_segs
    arr_copy = clone
    nth_el = arr_copy.pop
    arr_copy.segmentations(num_segs-1).append_to_each(nth_el) + 
    arr_copy.segmentations(num_segs).append_within_each(nth_el)
  end

  # These helper methods can't be private, since #segmentations invokes them with specific receivers
  protected
  
    # Appends a new element to the end of each subarray
    # Assumes an array of dimension == 3, e.g. the array returned by Array#segmentations
    # Example: [[[3,4]], [[3],[4]]].append_to_each(5) ==> [[[3,4], [5]],  [[3],[4],[5]]]
    #
    def append_to_each(appendee)
      map { |el| el << [appendee] }
    end

    # Appends a new element within each subarray 
    # Assumes an array of dimension == 3, e.g. the array returned by Array#segmentations
    # Example: [[[3,4]], [[3],[4]]].append_within_each(5) ==> [[[3,4,5]],  [[3,5],[4]],  [[3],[4,5]]]
    #
    def append_within_each(appendee)
      result = []
      self.each do |subarray|
        subarray.each_with_index do |group, j|
          subarray_copy = subarray.clone
          subarray_copy[j] = group + [appendee]
          result << subarray_copy
        end
      end
      result
    end
end

# Distributes an array of numeric values into num_buckets buckets
# such that the sums of each bucket are as equal as possible
#
# For fascinating background re: the hard math (and physics!) behind this problem,
# see http://www.americanscientist.org/issues/pub/the-easiest-hard-problem
#
# Example usage: fd = FairDistribution.new([5,5,4,4,3,3,3], 3)
#                fd.distribution =>     [ [5,4], [5,4], [3,3,3] ]
#                fd.max_bucket_sum =>   9
#
class FairDistribution

  attr_reader :values, :num_buckets
  
  def initialize(values_array, num_buckets)
    @values =  values_array
    @num_buckets = num_buckets
  end  

  # Lazily initialize @distribution, @max_bucket_sum, and @average_bucket_sum. For the first two,
  # the motivation is that these are expensive operations. For the third, the motivation is to
  # follow Jay Fields's recommendation to use attribute-based classes, rather than classes that
  # juggle both attributes and instance variables throughout their methods:
  #
  #       "The procedural behavior of initializing each attribute in a constructor is unnecessary
  #        and less maintainable than a class that deals exclusively with attributes."
  #        -- http://blog.jayfields.com/2007/07/ruby-lazily-initialized-attributes.html 
  # 
  def distribution
    @distribution ||= distribute_fairly
  end

  def max_bucket_sum
    @max_bucket_sum ||= distribution.map {|bucket| bucket.sum}.sort.last
  end
  
  # Since the values_array passed to a FairDistribution object might represent a variety of things,
  # we use max_bucket_sum as a generic method name. Here we provide the more specific method name 
  # requested by the challenge test suite:
  #
  alias :time_required :max_bucket_sum
  
  def average_bucket_sum
    @average_bucket_sum ||= values.sum.to_f / num_buckets
  end
  
  private
  
    # Distributes the values among the buckets such that each bucket's sums are as equal as possible
    # Returns the best possible distribution (or one of the best, in case of ties).
    # 
    # The sort works as follows:
    # Within each distribution, find the deviance between each bucket's sum and the ideal (average) bucket sum
    # Sort the distribution's buckets from highest deviance to lowest 
    # Then, sort the distributions as a whole based on these arrays of deviance values
    #
    def distribute_fairly
      return values if num_buckets == values.length
      num_usable_buckets = num_buckets > values.length ? values.length : num_buckets
      possible_distributions = values.segmentations(num_usable_buckets)
      sorted_distributions = possible_distributions.sort_by do |dist|
        dist.map { |bucket| (average_bucket_sum - bucket.sum).abs }.sort.reverse
      end  
      sorted_distributions.first
    end

end