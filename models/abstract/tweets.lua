local Tweet = require 'models.entity.tweet'
local View = require 'models.abstract.view'
local twitter = require 'data.twitter'

local Tweets = View:new()

function Tweets:layout ()
	return 'tweets'
end

function Tweets:timeline (handle, opts)
	opts = opts or {}
	local url = '/1.1/statuses/%s_timeline.json'
	local tl = handle and 'user' or 'home'
	local res, err = twitter:get(url:format(tl), {
		screen_name = handle;
		count = opts.count or 200;
		tweet_mode = 'extended';
	})

	if not res then return nil, err end
	return Tweet.map(res)
end

function Tweets:users (handles, opts)
	opts = opts or {}

	local query = ''
	for _, name in ipairs(handles) do
		local op = query:len() > 0 and '%20OR%20' or ''
		query = query .. op .. 'from%3A' .. name
	end

	local res, err = twitter:get('/1.1/search/tweets.json', {
		q = query;
		count = opts.count or 100;
		result_type = 'recent';
		tweet_mode = 'extended';
	})

	if not res then return res, err end
	return Tweet.map(res.statuses)
end

return Tweets
