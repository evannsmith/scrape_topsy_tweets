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
# Replace # now, deal with other special characters later
search_term = search.gsub("#", "%23").gsub("@", "%40").to_s
file_name = search.split(" ").join("_").tr("#", "")

puts "Search term: #{search}"
puts

# build list of feed uris
# go through top 500 most relevant
@topsy_all = Array.new
(0...500).step(10) do |start_index|
  # By day (d), week (w), month (m): most relevant
  @topsy_all << "http://topsy.com/s?q=" + search_term + "&window=m&type=tweet&offset=" + start_index.to_s
  @topsy_all << "http://topsy.com/s?q=" + search_term + "&window=w&type=tweet&offset=" + start_index.to_s
  @topsy_all << "http://topsy.com/s?q=" + search_term + "&window=d&type=tweet&offset=" + start_index.to_s
end

@topsy_all.sort!

# set the client timeout
client = Selenium::WebDriver::Remote::Http::Default.new
client.timeout = 120 # seconds, default is 30

# open browser
# phantomjs runs headless; change to :ff to drive firefox
driver = Selenium::WebDriver.for(:phantomjs, :http_client => client)
browser = Watir::Browser.new(driver)

# build list of the retweet uris
puts "Getting retweet result pages."
@rt_uris = Array.new

# point to each search result page of the original search results
(0..@topsy_all.length - 1).each do |index|
  browser.goto @topsy_all[index]
  begin
  	# puts "Results page: #{index}"
  	# wait until the page is loaded
 	 browser.div(:id => "results").wait_until_present
  	# pull the uris for the retweet listings
  	rt_links = browser.links
  	rt_links.each do |link|
  		if link.attribute_value("class") == "trackback-link"
  			@rt_uris << link.href
  		end
  	end
  rescue Exception => e
  	puts "Result page #{@topsy_all[index]} timed out."	
  end
end

# delete duplicate uris
@rt_uris = @rt_uris.uniq
puts
puts "There are #{@rt_uris.length} retweet results pages."

# build list of the tweet ids
@tweet_ids = Array.new

# for each retweet uri:
(0..@rt_uris.length - 1).each do |index|
	# puts "Retweet result: #{index}"
	# build list of offsets
	rt_offset = Array.new
	# only run through 1000 possible retweets
	(0...100).step(10) do |offset|
		rt_offset << @rt_uris[index] + "&offset=" + offset.to_s
	end
	
	# get the tweet ids
	(0..rt_offset.length - 1).each do |offset_index|
		browser.goto rt_offset[offset_index]
  		begin
  			# wait until the page is loaded
  			browser.div(:id => "results").wait_until_present
  			# parse
  			doc = Nokogiri::HTML.parse(browser.html)
  			# get unique tweet id from the tweet url
  			tweet_links = doc.css("a[class=muted]")
  			(0..tweet_links.length - 1).each do |link|
  				@tweet_ids << tweet_links[link]['href'].split("/").last.gsub(/[^0-9]/, "").to_s
  			end
  		rescue Exception => e
  			puts "Result page #{rt_offset[offset_index]} timed out."
  		end	
	end
end

browser.close

# delete duplicate ids
@tweet_ids = @tweet_ids.uniq

puts
puts "Writing file \"#{file_name}_rt_ids.csv\""

# write file
CSV.open("IDs/" + file_name + "_rt_ids.csv", "wb") do |row|
  row << ["tweet_id"]
  (0..@tweet_ids.length-1).each do |index|
    row << [
        @tweet_ids[index]
    ]
  end
end

duration = (Time.now - start)/60
puts
puts "Time elapsed: #{duration.round(2)} minutes"