#!/usr/bin/env ruby
=begin

RPCFN Challenge #6:: Fair Distribution
Author:: Marc Minneman

Complete Greedy Algorithm [Korf, 1998]

Optimal solution is discovered using a k-ary search tree that implements a greedy heuristic.

Jobs are sorted in order, and each job in turn is placed in each of k different subsets,
generating a k-ary tree. The leftmost branch places the next number in the subset with the
smallest sum so far, the next branch places it in the next larger subset, etc. Thus, the first
solution found is the greedy solution. By never placing a number in more than one empty subset,
we avoid generating duplicate partitions that differ only by a permutation of the subsets, and
produce all O(kn/k!) distinct k-way partitions of n elements. More generally, by never placing
a number in two different subsets with the same subset sum, we avoid generating different
partitions that have the same partition difference.

Finally, a perfect partition will have a difference of zero if the sum of the original jobs
is divisible by k, and a difference of one otherwise. Once a perfect partition is found, the
algorithm is terminated.

REFERENCE

[Korf, 1998] Richard E. Korf. A complete anytime algorithm
for number partitioning. Artificial Intelligence,
106(2):181–203, December 1998.

=end

class Array
  # calculates the sum of an array
  def calc_sum
    self.inject(0) {|s,x| s+=x}
  end
  # sorts an array of arrays based on sum amounts
  def sort_on_sum!
     self.sort! {|x,y| x.calc_sum <=> y.calc_sum}
  end
end

class FairDistribution

  # sentinal that ends search algorithm once a optimal solution is discovered
  class << self; attr_accessor :perfect_partition; end;

  attr_reader :time_required, :distribution

  def initialize(jobs, partition_cnt)
    raise ArgumentError, "Illegal job queue encountered" unless jobs.is_a? Array
    raise ArgumentError, "Illegal partition count encountered" unless partition_cnt.is_a? Fixnum
    (@time_required, @distribution = 0, (1..partition_cnt).map{[]}; return) if jobs.empty? || partition_cnt == 0
    # initiate k-ary search algorithm
    self.class.perfect_partition = false
    root = Node.new(0, jobs.clone.sort, (1..partition_cnt).map {[]})
    @time_required, @distribution = search(root) # return solution
  end

  private

  # implements CGA search as documented in overview
  def search(tree)
    # return completed partition along with time required by longest running subset
    return [tree.partitions[-1].calc_sum, tree.partitions] if tree.jobs.empty?
    # terminate gracefully if an optimal solution is discovered
    return nil if self.class.perfect_partition
    # recursively generate k-ary subtree
    result, min_time_parts =[], []
    tree.partitions.size.times do |k|
      # skip those branches that have duplicate subset sums (pruning optimization)
      next if k>0 && tree.partitions[k].calc_sum==tree.partitions[k-1].calc_sum
      s=search(Node.new(k, tree.jobs, tree.partitions)) # here's the recursive call
      # collect results
      unless s==nil
        result<<s
        min_time_parts<<s[0]
      end
      # break out of loop if an optimal solution is discovered
      break if self.class.perfect_partition
    end #search loop
    # return best solution from all k branches
    return result.assoc(min_time_parts.min)
  end

  # search tree node.
  #
  # precondition:     +jobs.sort+
  # class invariant:  +partitions.sort_on_sum!+
  #
  class Node
    attr_reader :jobs, :partitions
    def initialize(k, jobs, partitions)
      @jobs, @partitions = jobs.clone, Marshal.load(Marshal.dump(partitions)) # shallow copy is problematic
      # The jobs ar sorted in order.  The leftmost branch places the next number in the subset
      # with the smallest sum so far, the next branch places it in the next larger subset, etc.
      # Thus, the first solution found is the greedy solution.
      @partitions[k]<<@jobs.pop 
      # ensure class invariant
      @partitions.sort_on_sum!
      # when appropriate signal optimal solution
      FairDistribution.perfect_partition = true if @jobs.empty? && (@partitions[-1].calc_sum-@partitions[0].calc_sum).abs<=1
    end
  end

end
