# -*- coding: utf-8 -*-

import sys
import json
import twitter
import csv
import re
import pandas as pd
import yaml
from time import sleep
from twitter_authentication import *

# read file name variables 
with open('inputs.yml', 'r') as fn:
	cnf = yaml.load(fn)
tweet_id_file = cnf['tweet_id_file']
tweet_data_file = cnf['tweet_data_file']

# twitter authentication
api = twitter.Api(
 consumer_key = consumer_key,
 consumer_secret = consumer_secret,
 access_token_key = access_token_key,
 access_token_secret = access_token_secret
 )

# Read tweet ids
df = pd.read_csv("IDs/" + tweet_id_file + ".csv")
tweet_ids = df.tweet_id

print "There are " + str(len(tweet_ids)) + " tweets."
run_time = len(tweet_ids)*11.0/3600.0
print "Twitter is rate-limited; this will take approximately " + str(round(run_time, 2)) + " hours."
print "Progress will be noted every 100 tweets."
print ""

# Prepare CSV
f = open(tweet_data_file + ".csv",'wb')
writer = csv.writer(f, delimiter = ',', quotechar = '"')
header = ['id', 'created_at', 'text', 'favorite_count', 'retweet_count', 'place', 'longitude', 'latitude', 'lang', 'source', 'in_reply_to_user_id', 'in_reply_to_screen_name', 'user_id', 'user_name', 'user_screen_name', 'user_location', 'user_utc_offset', 'user_time_zone', 'user_statuses_count', 'user_followers_count', 'user_friends_count', 'user_favourites_count', 'user_listed_count', 'user_verified', 'user_created_at', 'url_1', 'url_2', 'url_3', 'hashtag_1', 'hashtag_2', 'hashtag_3', 'mention_1', 'mention_2', 'mention_3', 'retweet_id', 'retweet_created_at', 'retweet_user_id', 'retweet_user_screen_name']
writer.writerow(header)

# Pull out info
for index, id in enumerate(tweet_ids):
	if index % 100 == 0:
		print "Tweet: " + str(index)
	
	try:
		tweet = api.GetStatus(id=id)
		
		# Clean the html out of the tweet source
		source = re.search('.*>(.*)<.*', tweet.source).group(1)
		
		# Clean place data
		if tweet.place is None:
			place = tweet.place
		else:
			full_name = tweet.place[u'full_name'].encode('utf8', 'ignore')
			country = tweet.place[u'country'].encode('utf8', 'ignore')
			if country in full_name:
				place = full_name
			else:
				place = full_name + ", " + country
		
		# Extract coordinates
		if tweet.coordinates is None:
			longitude =  None
			latitude = None
		else:
			longitude = tweet.coordinates[u'coordinates'][0]
			latitude = tweet.coordinates[u'coordinates'][1]			

		# write big row
		row = [tweet.id, tweet.created_at, tweet.text, tweet.favorite_count, tweet.retweet_count, place, longitude, latitude, tweet.lang, source, tweet.in_reply_to_user_id, tweet.in_reply_to_screen_name, tweet.user.id, tweet.user.name, tweet.user.screen_name, tweet.user.location, tweet.user.utc_offset, tweet.user.time_zone, tweet.user.statuses_count, tweet.user.followers_count, tweet.user.friends_count, tweet.user.favourites_count, tweet.user.listed_count, tweet.user.verified, tweet.user.created_at]
		
		# separate out urls, hashtags, mentions, and retweet info
		if len(tweet.urls) == 0:
			row2 = ['NA', 'NA', 'NA']
		elif len(tweet.urls) == 1:
			row2 = [tweet.urls[0].expanded_url.encode('utf8', 'ignore'), 'NA', 'NA']
		elif len(tweet.urls) == 2:
			row2 = [tweet.urls[0].expanded_url.encode('utf8', 'ignore'), tweet.urls[1].expanded_url.encode('utf8', 'ignore'), 'NA']
		elif len(tweet.urls) >= 3:
			row2 = [tweet.urls[0].expanded_url.encode('utf8', 'ignore'), tweet.urls[1].expanded_url.encode('utf8', 'ignore'), tweet.urls[2].expanded_url.encode('utf8', 'ignore')]
	
		if len(tweet.hashtags) == 0:
			row3 = ['NA', 'NA', 'NA']
		elif len(tweet.hashtags) == 1:
			row3 = [tweet.hashtags[0].text.encode('utf8', 'ignore'), 'NA', 'NA']
		elif len(tweet.hashtags) == 2:
			row3 = [tweet.hashtags[0].text.encode('utf8', 'ignore'), tweet.hashtags[1].text.encode('utf8', 'ignore'), 'NA']
		elif len(tweet.hashtags) >= 3:
			row3 = [tweet.hashtags[0].text.encode('utf8', 'ignore'), tweet.hashtags[1].text.encode('utf8', 'ignore'), tweet.hashtags[2].text.encode('utf8', 'ignore')]
	
		if len(tweet.user_mentions) == 0:
			row4 = ['NA', 'NA', 'NA']
		elif len(tweet.user_mentions) == 1:
			row4 = [tweet.user_mentions[0].screen_name.encode('utf8', 'ignore'), 'NA', 'NA']
		elif len(tweet.user_mentions) == 2:
			row4 = [tweet.user_mentions[0].screen_name.encode('utf8', 'ignore'), tweet.user_mentions[1].screen_name.encode('utf8', 'ignore'), 'NA']
		elif len(tweet.user_mentions) >= 3:
			row4 = [tweet.user_mentions[0].screen_name.encode('utf8', 'ignore'), tweet.user_mentions[1].screen_name.encode('utf8', 'ignore'), tweet.user_mentions[2].screen_name.encode('utf8', 'ignore')]
	
		if tweet.retweeted_status is None:
			row5 = ['NA', 'NA', 'NA', 'NA']
		else:
			row5 = [tweet.retweeted_status.id, tweet.retweeted_status.created_at.encode('utf8', 'ignore'), tweet.retweeted_status.user.id, tweet.retweeted_status.user.screen_name.encode('utf8', 'ignore')]
		
		row.extend(row2)
		row.extend(row3)
		row.extend(row4)
		row.extend(row5)
		
		# convert to utf8
		subr = []
		for k in range(len(row)):
			if isinstance(row[k], unicode):
				subr.extend([row[k].encode('utf8', 'ignore')])
			else:
				subr.extend([row[k]])
		
		# write row		
		writer.writerow(subr)
	
		# Twitter limits GET-based requests to 350 per hour 
		sleep(11)
		
	except Exception:
		print "Error: Tweet " + str(id) + " (most likely) no longer exists."
		sleep(11)
		pass

# close csv
f.close()
