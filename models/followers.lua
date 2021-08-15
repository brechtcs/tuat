local Users = require 'models.abstract.users'
local cache = require 'data.cache'

local Followers = Users:new()

function Followers:init (opts)
	local to, err = self:resolve(opts.user, opts.id)
	if not to then return nil, err end
	local ids, err = cache:list_followers(to)
	if not ids then return nil, err end
	local users, err = self:lookup(ids)
	if not users then return nil, err end
	self.users = users
	return self
end

return Followers
