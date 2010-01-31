class FairDistribution
  def initialize(jobs, number_of_presses)
    @jobs, @number_of_presses = jobs, number_of_presses
    @massive = generate_massive_array
  end
  
  def time_required
    make_array_of_times(@massive).min
  end
      
  def distribution
    #massive = generate_massive_array
    var = variance(@massive)
    @massive[var.find_index(var.min)] #returns the first item of vararray that has the lowest variance
  end
  
  protected
  
  def generate_massive_array
    #Takes the array of jobs in @jobs and produces an array containing every possible combination of jobs
    #spread across the number of presses available
    #Achieves this by calling the split_array method for each item in the array repeatedly until
    #enough splitting has been done (@number_of_presses-1 times)
    massive_array = @jobs.dup
    (@number_of_presses-1).times do
      if massive_array[0].class == Array #Will be true after the first iteration
        working_array = []
        massive_array.each do |subarray| #Iterate over each item(subarray) in the massive_array
          new_array = split_array(subarray.pop) #pass the last element of current array to split_array (removes element from subarray)
          new_array.each {|item| working_array << (subarray + item)} #Combine the remainder of subarray with the resulting new_array
        end
        massive_array = working_array
      else
        massive_array = split_array(massive_array) #Applied during the first iteration when massive_array contains fixnums rather than arrays
      end
    end
    massive_array
  end
    
  def split_array(array)
    #Takes an array and produces an array containing every possible combination of the original array split into 2
    #Does this using a binary process and disregards any result containing an empty array
    big_array = []
    (2**array.length).times do |binary_index|
      extracted, left = [],[]
      array.length.times do |index|
        if (2**index & binary_index != 0)
          extracted << array[index]
        else
          left << array[index]
        end
      end
      big_array << [extracted,left] unless extracted == [] || left == []
    end
    big_array
  end
  
  def make_array_of_times(bigarray)
    #Takes an array of arrays and sums the total of each item of the subarray storing the highest sum in the returned array
    #(man, this is getting confusing, sorry my documentation is so poor - at least I'm trying to document it)
    newarr = []
    bigarray.each do |x|
      y = []
      x.each do |item|
        y << item.inject(:+)
      end
      newarr << y.max
    end
    newarr
  end
  
  def variance(big_array) #Calculate variance rather than sd to save CPU effort
    #Takes array in form [[[1,2,3],[4,5,6]],[[1,2,3],[4,5,6]]]
    #Sums individual values of each subarray (e.g. [[1,2,3],[4,5,6]] becomes [6,15])
    #Then calculates the variance of these numbers in each subarray storing them in an array corresponding to the original big_array
    var = [] #Empty array to store variances for each element
    big_array.each_with_index do |item,index|
      dupitem = item.dup #duplicate array so as not to alter array in caller
      dupitem.map! {|t| t.inject(:+)} #Sum contents of each array and convert to fixnum
      mean = dupitem.inject(:+).to_f / dupitem.length 
      dupitem.map! {|x| (x - mean) ** 2} #Calculate squares of deviations of each item from mean
      var[index] = dupitem.inject(:+) / (dupitem.length - 1) #Calculates variance and stores in var array
    end
    var
  end
  
end