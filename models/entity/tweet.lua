local Base = require 'models.entity.base'
local User = require 'models.entity.user'

local TS_PATTERN = '%w+%s+(%w+)%s+(%d%d)%s+(%d%d):(%d%d):%d%d%s+%S+%s+(%d+)'
local TS_FORMAT = '%d %s %d, %s:%s'
local LINK_FORMAT = '<a href="%s">%s</a>'

local Tweet = Base:new()

function Tweet.map (tweets)
	local list = {}
	for _, t in ipairs(tweets) do
		table.insert(list, Tweet.parse(t))
	end
	return list
end

function Tweet.parse (t)
	if not t then return nil end
	local tweet =  Tweet:new {
		id = t.id_str;
		content = Tweet.format_content(t);
		favorites = t.favorite_count;
		retweets = t.retweet_count;
		link = 'https://twitter.com/i/status/' .. t.id_str;
		quote = Tweet.parse(t.retweeted_status or t.quoted_status);
		timestamp = Tweet.format_timestamp(t.created_at);
		user = User.parse(t.user);
	}

	tweet.score = tweet:calculate_score()
	return tweet
end

function Tweet.format_content (t)
	if t.retweeted_status then return '' end

	local content = t.full_text:gsub('\n', '<br>')
	for _, e in ipairs(t.entities.urls) do
		content = Tweet.format_links(content, e)
	end
	for _, e in ipairs(t.entities.media or {}) do
		content = Tweet.format_links(content, e)
	end
	return '<p>' .. content .. '</p>'
end

function Tweet.format_links (content, entity)
	local link = LINK_FORMAT:format(entity.expanded_url, entity.display_url)
	return content:gsub(entity.url, Tweet.escape_patterns(link))
end

function Tweet.format_timestamp (str)
	local _, _, month, day, hour, min, year = str:find(TS_PATTERN)
	hour = (hour + 2) > 23 and (hour - 22) or (hour + 2)
	return TS_FORMAT:format(day, month, year, hour, min)
end

function Tweet.escape_patterns (text)
	return text:gsub("([^%w])", "%%%1")
end

function Tweet:calculate_score ()
	local retweeted = self.content:len() == 0
	local t = retweeted and self.quote or self
	local score = t.retweets + t.favorites / math.log(t.user.followers + 1)
	return retweeted and math.log10(score) or score
end

return Tweet
