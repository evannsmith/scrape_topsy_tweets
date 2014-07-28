require "csv"
require "yaml"

start = Time.now

# import search term 
fn = File.dirname(File.expand_path(__FILE__)) + '/inputs.yml'
cnf = YAML::load(File.open(fn))
tweet_id_file = cnf['tweet_id_file']

# arrays
@ids = Array.new

Dir.foreach("IDs") do |item|
	next if item == '.' or item == '..' or item == '.DS_Store'
	f = CSV.read("IDs/" + item, :headers => true)
	(0..f.length - 1).each do |index|
		@ids << f[index][0]
	end
end

# delete duplicate ids
@ids = @ids.uniq

# resave
CSV.open("IDs/" + tweet_id_file + ".csv", "wb") do |row|
  row << ["tweet_id"]
  (0..@ids.length-1).each do |index|
    row << [
        @ids[index]
    ]
  end
end

puts "There are #{@ids.length} total ids."
puts
duration = (Time.now - start)/60
puts "Time elapsed: #{duration.round(2)} minutes"
