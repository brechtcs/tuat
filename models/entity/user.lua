local Base = require 'models.entity.base'

local User = Base:new()

function User.map (users)
	local list = {}
	for _, u in ipairs(users) do
		table.insert(list, User.parse(u))
	end
	return list
end

function User.parse (u)
	return User:new {
		id = u.id_str;
		handle = u.screen_name;
		name = u.name;
		link = 'https://twitter.com/' .. u.screen_name;
		relation = User.parse_relation(u);
		description = u.description;
		location = u.location;
		followers = u.followers_count;
		influences = u.friends_count;
		protected = u.protected;
		verified = u.verified;
	}
end

function User.parse_description (u)
	local content = u.description:gsub('\n', '<br>')
	return '<p>' .. content .. '</p>'
end

function User.parse_relation (u)
	if u.following then
		return 'following'
	elseif u.follow_request_sent then
		return 'pending'
	else
		return 'not following'
	end
end

return User
