local cache = require 'data.cache'
local twitter = require 'data.twitter'

local name = assert(arg[1], 'no account name provided')
local account = assert(twitter:get('/1.1/users/show.json', { screen_name = name }))
local start = os.time()

local followers, influences = 0, 0
local one, two, err
local function cursor (res)
	return res and res.next_cursor_str or nil
end

local function lookup (endpoint, screen_name, cursor)
	local url = '/1.1/%s/ids.json'
	return twitter:get(url:format(endpoint), {
		screen_name = screen_name;
		stringify_ids = true;
		cursor = cursor;
	})
end

local function pad (str, len)
	return string.rep(' ', len - str:len()) .. str
end

local msg = '%s added to database: %s/%s'
local function output (category, current, total)
	current = tostring(current)
	total = tostring(total)
	print(msg:format(category, pad(current, total:len()), total))
end

while true do
	one, err = lookup('followers', name, cursor(one))
	if not one then
		print('failed to get followers: ' .. err) break
	end

	local follows = assert(cache:insert_follows(one.ids, { account.id_str }, start))
	followers = followers + follows
	output('followers', followers, account.followers_count)
	if one.next_cursor == 0 then break end
end

while true do
	two, err = lookup('friends', name, cursor(two))
	if not two then
		print('failed to get influences: ' .. err) break
	end

	local follows = assert(cache:insert_follows({ account.id_str }, two.ids, start))
	influences = influences + follows
	output('influences', influences, account.friends_count)
	if two.next_cursor == 0 then break end
end

local pruned = assert(cache:prune_follows(account.id_str, start))
print('follows pruned from database: ' .. pruned)
