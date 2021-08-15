local Users = require 'models.abstract.users'
local cache = require 'data.cache'

local Mutuals = Users:new()

function Mutuals:init (opts)
	local to, err = self:resolve(opts.user, opts.id)
	if not to then return nil, err end
	local ids, err = cache:list_mutuals(to)
	if not ids then return nil, err end
	local users, err = self:lookup(ids)
	if not users then return nil, err end
	self.users = users
	return self
end

return Mutuals
