local Users = require 'models.abstract.users'
local cache = require 'data.cache'

local Influences = Users:new()

function Influences:init (opts)
	local from, err = self:resolve(opts.user, opts.id)
	if not from then return nil, err end
	local ids, err = cache:list_influences(from)
	if not ids then return nil, err end
	local users, err = self:lookup(ids)
	if not users then return nil, err end
	self.users = users
	return self
end

return Influences
