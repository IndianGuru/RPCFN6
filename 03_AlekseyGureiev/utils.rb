# Simple additions to the generic array that are used to calculate the
# sum of items and iterate over the elements in a specific fashion.
class Array

  # Returns the sum of all values in the array
  def sum
    self.inject(0.0) do |memo, value|
      memo + (value.is_a?(Array) ? value.total : value)
    end
  end
  
  # Iterates over all unique (based on their sum) combinations of elements.
  # [1,2,3] -> [1], [1,2], [1,2,3], [2], [2, 3] (see [3] is omitted as being equial to [1,2])
  def each_combination(i = 0, c = [], sums = [], &block)
    (i ... self.size).each do |x|
      combo = c + [ self[x] ]
      sum = combo.sum
      
      unless sums.include?(sum)
        sums << sum
        block.call combo
        each_combination(x + 1, combo, sums, &block)
      end
    end
  end

end
