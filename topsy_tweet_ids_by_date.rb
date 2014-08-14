require "watir-webdriver"
require "watir-webdriver/wait"
require "nokogiri"
require "open-uri"
require "csv"
require "yaml"
require "time"

# Author: Evann Smith
# Version: 0.1

start = Time.now

# import search term
fn = File.dirname(File.expand_path(__FILE__)) + '/inputs.yml'
cnf = YAML::load(File.open(fn))
search = cnf['search']
start_year = cnf['start_year']
start_month = cnf['start_month']
start_day = cnf['start_day']
end_year = cnf['end_year']
end_month = cnf['end_month']
end_day = cnf['end_day']
# Replace # now, deal with other special characters later
search_term = search.gsub("#", "%23").gsub("@", "%40").to_s
file_name = search.split(" ").join("_").tr("#", "").tr("@", "")

puts "Search term: #{search}"
puts

# create list of start dates
puts "Generating date ranges:"
start_date = Date.new(start_year,start_month,start_day).to_time
end_date = Date.new(end_year,end_month,end_day).to_time
puts "Start date: #{start_date}"
puts "End date: #{end_date}"

# set start date
@topsy_dates = [start_date.to_i]
next_day = start_date + 24*60*60
# generate the next dates conditional on the end date
while next_day < (end_date + 2*24*60*60) do
	@topsy_dates << next_day.to_i
	next_day = next_day + 24*60*60
end
puts "Getting #{@topsy_dates.length-1} days of tweets."
puts

# build time range
@topsy_all = Array.new
(0..@topsy_dates.length - 2).each do |index|
	date_range = "&mintime=" + @topsy_dates[index].to_s + "&maxtime=" + @topsy_dates[index+1].to_s
	# build list of feed uris for the "all time" search results
	(0...1000).step(10) do |start_index|
	# Specific dates
		@topsy_all << "http://topsy.com/s?q=" + search_term + "&type=tweet&sort=-date&offset=" + start_index.to_s + date_range
	end
end

# set the client timeout
client = Selenium::WebDriver::Remote::Http::Default.new
client.timeout = 120 # seconds, default is 30

# open browser
# phantomjs runs headless; change to :ff to drive firefox
driver = Selenium::WebDriver.for(:phantomjs, :http_client => client)
browser = Watir::Browser.new(driver)

# build list of the tweet ids
@tweet_ids = Array.new

puts "Getting tweet ids:"

# point to each search result page
(0..@topsy_all.length - 1).each do |index|
  if index % 100 == 0
  	puts "Day: #{index/100}"
  end
  browser.goto @topsy_all[index]
  begin
  	# wait until the page is loaded
  	browser.div(:id => "results").wait_until_present
  	# parse
  	doc = Nokogiri::HTML.parse(browser.html)
  	# get unique tweet id from the tweet url
  	@tweet_links = doc.css("a[class=muted]")
  	(0..@tweet_links.length - 1).each do |link|
  		@tweet_ids << @tweet_links[link]['href'].split("/").last.gsub(/[^0-9]/, "").to_s
  	end
  rescue Exception => e
  	puts "Result page #{@topsy_all[index]} timed out."
  end
end

browser.close

# delete duplicate ids
@tweet_ids = @tweet_ids.uniq

puts
puts "Writing file: #{file_name}_ids.csv"
puts

# write file
CSV.open("IDs/" + file_name + "_ids_by_date.csv", "wb") do |row|
  row << ["tweet_id"]
  (0..@tweet_ids.length-1).each do |index|
    row << [
        @tweet_ids[index]
    ]
  end
end

duration = (Time.now - start)/60
puts "Time elapsed: #{duration.round(2)} minutes"
