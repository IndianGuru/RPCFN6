# vim: ts=3 sw=3

class FairDistribution
	def initialize( jobs, groups)
		@jobs = jobs.sort {|x,y| y <=> x }
		@o_c = jobs.length
		@g_c = groups
		@result = nil
	end
	def each
		# simplifications for 1 printer 
		# ( over code don't catch well 
		# case when first and the last 
		# printer is the same )
		if @g_c == 1 then
			yield @jobs
			return
		end
		st = (0...@o_c).map{-1}                # stack to work without recursion
		sp = 0                                 # stack pointer
		# Optimization 1:
		# first order is always on first printer
		# second order is on first or second printer and etc.
		# We exclude full simetric results from output
		stm = (1..@o_c).map{|i| [i, @g_c].min} # hi bound of variants for each job (for optimisation)
		sta = (0..@o_c).map{ Array.new(@g_c) }     # pre culc weigths of jobs of printers
		sta[0] = (0...@g_c).map{0}
		stf = (0...@o_c).map{1}							  # flags for stack
		stv = (0...@o_c).map{ Array.new(@g_c) }
		stvi = (0...@o_c).map{ -1 }
		mean = @jobs.inject{|s,i| s + i} / @g_c
		while true do
			rp = st[sp]
			if stf[sp] == 1 then
				stf[sp] = 0
				sta[sp + 1] = sta[sp].clone
				sta[sp + 1][rp] += @jobs[sp]
				# Optimization 2:
				# If we skip overload - it's not 
				# optinum combinations anyway
				stv[sp] = (0...stm[sp]).find_all{|i| sta[sp][i] < mean }.push(-1)
				stvi[sp] = 0
			end
			
			r = st[sp] = stv[sp][ stvi[sp] ]
			stvi[sp] += 1

			if r == -1 then
				stf[sp] = 1
				sp -= 1
			else
				sta[sp + 1][r]  += @jobs[sp]
				sta[sp + 1][rp] -= @jobs[sp] 
				sp += 1
			end
			if sp == @o_c then
				sp -= 1
				dist = self.jobs_distribution(st)
				yield [st, # distribution 
						 sta[sp + 1].map{|v| (v - mean)**2}.inject{|s,i| s+ i}, # function to get minimum
						 dist.map{|v| v.inject(0){|s,i| s + i} }.max, # work time
						 dist # distribution with substitution of values
						]
			elsif sp == -1 then
				return
			end
		end
	end

	def jobs_distribution(st)
		r = Array.new(@g_c){[]}
		for g, i in st.zip( (0...@o_c).to_a ) do
			r[g].push( @jobs[i] )
		end
		return r
	end

	def culc_distribution
		if @result != nil then
			return @result
		end
		min = nil
		for d in self do
			min = d if min == nil || min[1] > d[1]
		end
		@result = min
	end

	def time_required
		self.culc_distribution()[2]
	end
	def distribution
		self.culc_distribution()[3]
	end
end

