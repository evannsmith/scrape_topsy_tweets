scrape_topsy_tweets
======================

Scrape historical tweet ids from topsy.com

Original tweets and retweets are returned differently by topsy. 
- topsy_tweet_ids_by_date.rb scrapes tweet ids (corresponding to the search term and start and end dates in the inputs file) and saves them to a folder called "IDs".
- topsy_retweet_ids does the same for retweets.
- tweet_id_join.rb pulls them all together.
- tweet_data_by_id.py pulls the twitter data from the REST api, parses the json, and saves it as a csv
