n = 100
ruby = '/path/to/ruby'
error_counter = 0

n.times {
  result = `#{ruby} test_solution_acceptance.rb full`
  # Started
  # ..F..
  # Finished
  result =~ /Started\n([.F]{5})\nFinished/
  results = $1.chars.map { |t| t == '.' }
  errors = results.count(false)
  if errors > 1
    puts "#{errors} errors!"
    print '^'
  elsif errors == 1
    error_counter += 1
    print 'v'
  else
    print '.'
  end
}

puts "#{error_counter} errors/#{n} tests = #{((n-error_counter).to_f/n*100).round}%"
