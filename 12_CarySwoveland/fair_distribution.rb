=begin
Cary Swoveland
Ruby v 1.8.7

I solved the problem of allocating jobs to machines using a tree search, sequentially
allocating jobs to machines. The search identifies an allocation that minimimizes
"finish time", by which I mean the maximum of each machine's completion time.  If
multiple allocations exist with the minimum finish time, it identifies one that,
among all such minima, minimizes the variance of the job completion times.

I have taken two steps to improve the efficiency of the search. 

1. I pruned the search tree.  If there are J jobs and M machines, the tree search would
have M^J end nodes. Among these, however, only M^J/M! need be considered, as there are
M! "equivalent" permutations of each assignment, obtained by simply relabeling machines.
If, for example, one end node corresponds to J0 = {2,3,5}, J1 = {4,0} and J2 = {1,6},
where Jm is the set of jobs assigned to machine m, there is no need to examine the
other 5 (3!-1) end nodes obtained by merely relabeling the machines; e.g., J0 = {4,0},
J1 = {2,3,5}, J2 = {1,6}.  Pruning the tree down to M^J/M! is a non-trival task. I have
elected a less ambitious goal, one which employs a procedure that prunes the number of
end nodes (from M^J) to M!M^(J-M).  Specifically, if j is the jth job assigned, I only
consider assigning it to machines 0..min(j,M).  That is, I arbitarily assign job j = 0
to machine 0 (assigning it to any othe machine is just a relabeling of machines),
consider allocating job 1 to machines 0 and 1 only, job 2 to machines 0, 1, and 2 only,
etc. I consider allocating each job j >= m to all m machines.

2. Having a "good" allocation of jobs to machines greatly reduces the search time, as it
permits many branches of the search tree to be skipped.  Consider, for example, a branch
in the tree at which job j is to be assigned.  Jobs 0..j-1 have been assigned in branches
closer to the top of the tree, resulting in a machine completion time of mt(m) for each
machine m.  If b is currently the best finish time found to date (i.e., for the assignment
of all J jobs) and jt(j) is the time required for job j, we need not consider assigning
job j to any machine m for which jt(j) + mt(m) > b, for the finish time for any assignment
of jobs j+1, j+2,..,J-1 (together with already-assigned jobs 0,1,..,j) will be greater
than b.  (We cannot dismiss assignments for which jt(j) + mt(m) = b, for a solution
may exist along that branch with a finish time of b and with a smaller variance than
that of the best known solution to date.)

Merely navigating the search tree will produce a decreasing series of best known finish
times b1 > b2 > b3.. which can be used to disregard branches, but it is much more
efficient to begin the tree search with a "good" solution.  I use a hueristic to obtain
a "good" starting solution.  It involves four steps:

a) Relabel the jobs in order of decreasing job time.  That is, job 0--the first job
to be asigned in the search tree--has the largest job time, job 1 has the next largest job
time, etc.  Not only is this reordering needed for the heuristic, but it is very
effective for disregarding branches of the search tree that are close to the top, thereby
eliminating large numbers of end nodes from consideration.

b) Initially assign jobs to machines using a "forward-backward sweeping" procedure.  This
can best be explained by example.  Suppose there are 3 machines.  (Recall the jobs are
ordered by decreasing job time.) Then the allocation of jobs to machines (j->m) would
be as follows:
forward sweep: 0->0, 1->1, 2->2,
then backward sweep 3->2, 4->1, 5->0,
then forward sweep: 6->0, 7->1, 8->2
etc. This simple procedure produces surprising good solutions (optimal solutions for two
of the five test problems).

c) Attempt to improve the solution (reduce finish time) by reallocating one of the jobs
assigned to the "critical machine"--the machine with the largest completion time--to
another machine.  (Should the largest completion time be shared two or more machines,
any of these may be designated as the "critical machine".)

d) When it is no longer possible to improve the solution by reallocating a job from the
critical machine to some other machine, an attempt is made to improve the solution by
swapping one of the jobs assigned to the critical machine with a job assigned to one
of the other machines.  If an improvement is found by such a swap, step c) is repeated; the
heuristic terminates when no further improvement is possible by either reallocating or
swapping jobs.

The heuristic produces excellent assignments. It produced the optimal solution for all five
test problems (i.e., the tree searches merely confirmed the solutions to be optimal) and for
several of my own test problems, one with 9 machines and 21 jobs.  The typical efficiency
of the heuristic is illustrated by its application to a test problem with 21 jobs and 7
machines.  The heuristic produced a best value of 10.67, which was improved by the tree
search to an optimal value of 10.58.  The tree for that problem had 3.4 x 10^15 end nodes,
but it was only necessary to evaluate 3,161 of them. (The tree search reduced the best
finish time five time before reaching the optimum, and reduced the variance in ties for
best-known solution 12 times.) 
=end

TIME_REQ_FAC = 0.000001
VARIANCE_FAC = 0.000001


class FairDistribution
    attr_reader :time_required, :variance, :distribution
    
  def initialize(job_times, n_machines)
    @n_machines = n_machines
    @machine_range = (0...@n_machines)

    @n_jobs = job_times.length
    @job_range = (0...@n_jobs)
    @job_times = job_times.dup
    @last_job = @n_jobs - 1
    @last_job_time
    # Due to symmetry, there is no need to consider all mappings of jobs to
    # machines.  For example, we can arbitrarily assign job 0 to machine 0,
    # job 1 to either machine 0 or 1, job 2 to machine 0, 1, or 2, etc.
    @max_machine_by_job_range = Array.new(@n_jobs)
    @job_range.each { |j| @max_machine_by_job_range[j] = (0..[j, @n_machines-1].min) }

    @opt = Array.new(@n_jobs) # @opt[j] is machine to which job j is assigned
    @distribution = Array.new(@n_machines)
    @machine_range.each { |m| @distribution[m] = Array.new }

    @n_end_nodes_visited = 0
    @n_branches_visited = 0
    @n_time_required_reductions = 0
    @n_variance_comparisons = 0
    @n_variance_reductions = 0
  
    avg = (job_times.min + job_times.max)/2
    @time_req_tol = TIME_REQ_FAC * avg
    @variance_tol = VARIANCE_FAC * avg
    
    job_map = Array.new(@n_jobs)
    
    # Reorder @job_times by decreasing time.  job_map[j] is original job with the
    # jth smallest time; e,g,, job_map[0] is the job with largest time, etc.
    reorder_jobs_by_decreasing_time(job_map)
    @last_job_time = @job_times[@n_jobs - 1]
    
    # Find a good solution for use as an upper bound to skip branches
    # of the enumeration treee.
    find_good_solution # Results put in @opt[], @time_required and @variance

    machine_times = Array.new(@n_machines, 0.0)
     
    # Find optimal allocation with no jobs assigned.
    search_tree(0, 0.0, 0.0, machine_times)
    return_jobs_to_original_order(job_map)
    @job_times = job_times.dup
    puts "\nMaximum machine completion time after searching tree = #{@time_required}"
    puts "Variance of job completion times for optimal solution = #{@variance}"
    construct_machine_assignments # Prepare @distribution
    print_machine_assignments
    print_search_statistics
  end
  
# ---------------------------------------------------- 
private
# ---------------------------------------------------- 
  def find_good_solution

    # Provide an initial assignment of jobs to machines.  The procedure used is easiest
    # to explain by example.  Suppose there are 8 jobs and three machines.  Recall that
    # jobs are ordered by decreasing time.  The "back and forth" assignent would be:
    # 0=>0, 1=>1, 2=>2, 3=>2, 4=>1, 5=>0, 6=>0, 7=>1
    @job_range.each { |j| @opt[j] = \
      j/@n_machines % 2 == 0 ? j % @n_machines : @n_machines - 1 - (j % @n_machines) }  
    construct_machine_assignments
    
    # Construct machine_times from @opt[], where machine_times[m] contains the completion time
    # for machine m.
    machine_times = Array.new(@n_machines)
    build_machine_times(machine_times)
    @time_required = machine_times.max
    puts "Maximum machine completion time after initial allocation of jobs = #{@time_required}."

    # Now perform reassignments and pairwise exchanges to reduce @time_required until
    # no further reduction is possible.  Each time through the loop:
    # 1. identify the "critical" machine; i.e., the machine m for which
    #   machine_times[m] = machine_times.max (or any machines m for which
    #   machine_times[m] = machine_times.max, if two or more machines satisfy this condition).
    # 2. Attempt to reduce machine_times.max by moving one of the jobs assigned to the
    #   critical machine to another machine.  If, and as soon as, such an improvement
    #   is found, this step is completed, step 3 is skipped and looping continues.
    #   Step 3 is performed if and only if no improvement is found in this step.
    # 3. Attempt to reduce machine_times.max by swapping one of the jobs assigned to the      
    #   critical machine with a job assigned to another machine.  If, and as soon as,
    #   such an improvement is found, this step is completed looping continues; else
    #   we have bound the best "good" solution so we exit the loop and return.

    # Loop as long as improvements are made.
    improvement = true
    while improvement do
      # Find machine with largest completion time
      critical_machine = machine_times.each_with_index.max[1]

      # Try reallocating a job on the critical machine to a different machine.  If no improvement,
      # try swapping a job on the critical machine with a job on another machine.
      improvement = reallocate_job(critical_machine, machine_times)
      if not improvement
        improvement = swap_jobs(critical_machine, machine_times)
      end
    end  
    @time_required = machine_times.max
    machine_completion_time_variance(machine_times)
    puts "Maximum machine completion time after completion of heuristic"
    puts "that reallocates and swaps jobs among machines = #{@time_required}."
  end

# ----------------------------------------------------
  def reallocate_job(critical_machine, machine_times)
    # Loop over jobs assigned to critical_machine
    @distribution[critical_machine].each { |j|
      # Try reassigning job j assigned to m to another machine
      return true if reallocate_specific_job(critical_machine, j, machine_times)
    }
    return false    
  end
    
# ----------------------------------------------------
  def reallocate_specific_job(critical_machine, job_to_reassign, machine_times)
    # Can skip any machine whose current machine_times is >= max_machine_time (below),
    # as assigning job_to_reassign to that machine would increase its machine time to
    # at least the current critical machine time.
    max_machine_time = machine_times[critical_machine] - @job_times[job_to_reassign]
    @machine_range.each { |m|
      if machine_times[m] < max_machine_time # Note the critical machine will be skipped
        # Reassign job_to_reassign to machine m and update @distribution
        reallocate_update_opt_and_distribution(critical_machine, job_to_reassign, m)
        # Adjust machine completion times
        update_machine_times(critical_machine, m, @job_times[job_to_reassign], machine_times)
        return true
      end
    }
    return false
  end

# ----------------------------------------------------
  def reallocate_update_opt_and_distribution(critical_machine, job_to_reassign, target_machine)
    @opt[job_to_reassign] = target_machine
    @distribution[critical_machine].delete(job_to_reassign)
    @distribution[target_machine] << job_to_reassign
  end

# ----------------------------------------------------
  def update_machine_times(critical_machine, target_machine, diff_job_time, machine_times)
    machine_times[critical_machine] -= diff_job_time
    machine_times[target_machine] += diff_job_time
  end  

# ----------------------------------------------------
  # Try pairwise exchanges  
  def swap_jobs(critical_machine, machine_times)
    @distribution[critical_machine].each { |j|
      return true if swap_job_pair(critical_machine, j, machine_times)
    }
    return false
  end    
           
# ----------------------------------------------------
  def swap_job_pair(critical_machine, critical_job, machine_times)
    @machine_range.each { |m|
      return true if m != critical_machine and \
        swap_to_target_machine(critical_machine, critical_job, m, machine_times)
    }
    return false
  end
    
# ----------------------------------------------------
  def swap_to_target_machine(critical_machine, critical_job, target_machine, machine_times)
    # The job swapped from the target machine must have a job time greater than
    # min_target_job_time; otherwise, the target machine time would become
    # as least as large as the current critical machine time.

    critical_job_time = @job_times[critical_job]
    
    min_target_job_time = machine_times[target_machine] - machine_times[critical_machine]  + \
      critical_job_time

    # Loop over jobs assigned to target machine
    @distribution[target_machine].each { |j|
      jt = @job_times[j]
      if jt < critical_job_time and jt > min_target_job_time
        # Swap critical_job on critical_machine with job j on target machine and update
        # @distribution   
        update_opt_and_distribution(critical_machine, critical_job, target_machine, j)
        # Adjust machine completion times
        update_machine_times(critical_machine, target_machine, critical_job_time - jt, machine_times)
        return true
        end   
    }
    return false
  end

# ----------------------------------------------------
  def update_opt_and_distribution(critical_machine, critical_job, target_machine, target_job)
    @opt[critical_job] = target_machine
    @opt[target_job] = critical_machine
    i = @distribution[critical_machine].index(critical_job)
    @distribution[critical_machine][i] = target_job
    i = @distribution[target_machine].index(target_job)
    @distribution[target_machine][i] = critical_job
  end

# ---------------------------------------------------- 
  def machine_completion_time_variance(machine_times)
    s = 0.0; ss = 0.0
    machine_times.each { |t| s += t ; ss += t*t }
    @variance = ss/@n_machines - (s/@n_machines)*(s/@n_machines)
  end   

# ----------------------------------------------------
# Optimize allocation of jobs >= first_unassigned_job, given allocation of
# jobs < first_unassigned_job. Return true if a better job assignment is found;
# else false. Job first_unassigned_job is assigned to machine @opt[first_unassigned_job].

  def search_tree(first_unassigned_job, sum_mt, sum_mt2, machine_times)
    # See if first_unassigned_job is the last job to assign
    return assign_last_job(sum_mt, sum_mt2, machine_times) if first_unassigned_job == @last_job
    @n_branches_visited += 1 # For search statistics.
    
    # first_unassigned_job is not last job  
    improvement = false #default return value
    jt = @job_times[first_unassigned_job]
    # For jobs j, 0 <= j <@n_machines, need only consider machines 0,..,j. 
    @max_machine_by_job_range[first_unassigned_job].each { |m|
      # Skip assignment to machine m if that cannot be optimal
      new_time = jt + machine_times[m]
      # Assume new_time <= @time_required iff new_time <= @time_required + @time_req_tol      
      if new_time <= @time_required + @time_req_tol      
        # Try assigning job first_unassigned_job to machine m.  machine_times[m] reversed below.
        save_time = machine_times[m]
        machine_times[m] += jt
        # Optimize allocation of jobs > first_unassigned_job, given allocation of
        # jobs <= first_unassigned_job
        if search_tree(first_unassigned_job + 1, sum_mt+new_time-save_time, \
          sum_mt2+new_time*new_time-save_time*save_time, machine_times)
          # A new best solution has been found
          @opt[first_unassigned_job] = m
          improvement = true
        end
        machine_times[m] = save_time # Return machine m to it's previous state
      end # t + machine_times[m] <= @time_required
    } # @machine_range.each { |m|
    return improvement
  end

# ---------------------------------------------------- 
  def assign_last_job(sum_mt, sum_mt2, machine_times)
    # Consider assigning the last job to the machine that finishes first (or, if two or more machines
    # finish at the same time, before all other machines, to one of the machines that finish first).

    @n_end_nodes_visited += 1 # For reporting algorithm efficiency statistics.
    puts "After visiting #{@n_end_nodes_visited} end nodes, best completion time = #{@time_required}" \
      if @n_end_nodes_visited % 100000 == 0
    # Assign last job to machine that finishes first.  If there are ties, assign to any
    # of the tied machines, as time_required and variance will be the same for all.
    min_completion_time = machine_times.min

    # No chance of having found an improved solution if assigning the last job to the
    # machine that finishes first causes that machine to have a finish time > @time_required
    return false if min_completion_time + @last_job_time > @time_required + @time_req_tol
    

    # See if assignment results in a worse solution, in which case return false.
    m = machine_times.index(min_completion_time)
    machine_times[m] += @last_job_time
    test_time = machine_times.max
    machine_times[m] = min_completion_time
    
    # Assume test_time > @time_required iff test_time > @time_required + @time_req_tol
    return false if test_time > @time_required + @time_req_tol

    # See if assigment reduces @time_required, in which case update @time_required,
    # @variance and @opt[@last_job] and return true.
    # Assume test_time < @time_required iff Assume test_time < @time_required - @time_req_tol
    if test_time < @time_required - @time_req_tol
      @n_time_required_reductions += 1
      @time_required = test_time
      @variance = calc_variance(sum_mt, sum_mt2, min_completion_time)
      @opt[@last_job] = m
      return true
    end

    # Only remaining possibility is that the completion time for this solution equals
    # the best completion time found previously, @time_required, in which case
    # the better solution is the one with the lower variance.
    @n_variance_comparisons += 1

    var = calc_variance(sum_mt, sum_mt2, min_completion_time)
    # Assume var < @variance iff var < @variance - @variance_tol
    return false if var >= @variance - @variance_tol 
    
    # Have found a new best solution. No improvement in @time_required, but reduction in variance.
    @n_variance_reductions += 1
    @opt[@last_job] = m
    @variance = var
    return true
  end
  
# ----------------------------------------------------
def calc_variance(sum_mt, sum_mt2, previous_machine_time)
  s = sum_mt + @last_job_time
  new_machine_time = previous_machine_time + @last_job_time    
  ss = sum_mt2 - (previous_machine_time*previous_machine_time) + (new_machine_time*new_machine_time)
  return ss/@n_machines - (s/@n_machines)*(s/@n_machines)
end

# ----------------------------------------------------
  def return_jobs_to_original_order(job_map)
    opt_copy = @opt.dup
    @job_range.each { |j| @opt[job_map[j]] = opt_copy[j] }
  end

# ---------------------------------------------------- 
  def construct_machine_assignments # Prepare @distribution
    @machine_range.each { |m| @distribution[m] = [] }
    @job_range.each { |j| @distribution[@opt[j]] << j }
  end    
  
# ---------------------------------------------------- 
  def print_machine_assignments
    puts "Machines->[jobs] "
    @machine_range.each { |m|
      print "Machine #{m}->["
      time = 0.0
      print_space = false
      @distribution[m].each { |j|
        time += @job_times[j]
        print " " if print_space
        print_space = true
        print "#{j}"
      }
      puts "] time = #{time}"
    }  
  end

  ## ---------------------------------------------------- 
  def build_machine_times(machine_times)
    @machine_range.each { |m| machine_times[m] = 0 }
    @job_range.each { |j| machine_times[@opt[j]] += @job_times[j] }
  end
    
# ---------------------------------------------------- 
  def reorder_jobs_by_decreasing_time(job_map)
    jt = Array.new
    @job_range.each { |j| jt << [j,@job_times[j]] }
    jt = jt.sort_by { |e| e[1] }.reverse
    # job_map[j] is job with jth smallest time; i.e., job_map[0] is job with largest time, etc.
    @job_range.each { |j| job_map[j] = jt[j][0]; @job_times[j] = jt[j][1] } 
  end

# ----------------------------------------------------
  def print_search_statistics
    en = 1
    (1..@n_machines).each { |m| en *= m }
    (@n_jobs-@n_machines).times { en *= @n_machines } # To avoid including the math module
    puts "\nBranches visited = #{@n_branches_visited}, end nodes visited = #{@n_end_nodes_visited}"
    puts "Total end nodes = #{en}, fraction visited = #{@n_end_nodes_visited/en.to_f}"
    puts "Reductions in maximum machine completion time = #{@n_time_required_reductions}" 
    puts "Comparisons of machine completion time variances = #{@n_variance_comparisons}"
    puts "Reductions in machine completion time variance = #{@n_variance_reductions}\n\n"
  end

# ---------------------------------------------------- 

end # Clase FairDistribution
