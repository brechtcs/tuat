local User = require 'models.entity.user'
local View = require 'models.abstract.view'
local twitter = require 'data.twitter'

local Users = View:new()

function Users:layout ()
	return 'users'
end

function Users:format (format)
	if format == 'flags' then
		local names = ''
		for _, u in ipairs(self.users) do
			if u.screen_name then
				local s = names:len() > 0 and '\n' or ''
				names = names .. s .. '--user=' .. u.screen_name
			end
		end
		return names, { ['Content-Type'] = 'text/plain' }
	end
	return View.format(self, format)
end

function Users:lookup (ids, handles)
	local screen_name = ''
	for _, handle in ipairs(handles or {}) do
		local sep = screen_name:len() > 0 and ',' or ''
		screen_name = screen_name .. sep .. handle 
	end

	local user_id = ''
	for _, id in ipairs(ids or {}) do
		local sep = user_id:len() > 0 and ',' or ''
		user_id = user_id .. sep .. id 
	end

	local params = {}
	params.screen_name = screen_name:len() > 0 and screen_name
	params.user_id = user_id:len() > 0 and user_id

	local res, err = twitter:get('/1.1/users/lookup.json', params)
	if not res then return nil, err end
	return User.map(res)
end

function Users:resolve (handles, ids)
	local users, err = self:lookup(nil, handles)
	if not users then return nil, err end

	ids = ids or {}
	for _, u in ipairs(users) do
		table.insert(ids, u.id)
	end
	return ids
end

return Users
