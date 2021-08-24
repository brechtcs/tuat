local Tweet = require 'models.entity.tweet'
local View = require 'models.abstract.tweets'

local Timeline = View:new()

function Timeline:init (opts)
	local tweets, err = self:load(opts)
	if not tweets then return nil, err end
	self:setcursor(tweets[#tweets])
	self:rank(tweets, not opts.user)
	return self
end

function Timeline:load (opts)
	if opts.user and #opts.user > 1 then
		return self:users(opts.user)
	else
		return self:timeline(opts.user and opts.user[1])
	end
end

function Timeline:rank (tweets, compact)
	local tl = {}
	local users = {}

	for _, tweet in ipairs(tweets) do
		local id = tweet.user.id
		local prev = users[id] and tl[users[id]]
		if not compact or not prev then
			table.insert(tl, tweet)
			users[id] = #tl
		elseif tweet.score > prev.score then
			tl[users[id]] = tweet
		end
	end
	table.sort(tl, function (a,b) return a.score > b.score end)
	self.tweets = tl
end

function Timeline:setcursor (tweet)
	self.cursor = tweet and tweet.id_str
end

return Timeline
