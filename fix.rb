require 'csv'
CSV.foreach("wrha_wait_times.csv") do |row|
  puts "#{row[0].to_i + 18000},\"#{row[1]}\",#{row[2]},#{row[3]},#{row[4]}"
end
