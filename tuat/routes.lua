local neturl = require 'net.url'
local router = require 'router'

local function redirect ()
	local base = os.getenv('TUAT_BASE_URI') or ''
	return nil, 301, { Location = base .. '/timeline' }
end

local function view (opts)
	local Model = require('models.' .. opts.view)
	local instance = Model:new()
	assert(instance:init(opts))

	if opts.format then
		return instance:format(opts.format)
	else
		return instance:render()
	end
end

local routes = router.new()
routes:get('/', redirect)
routes:get('/:view', view)

return function (method, uri, query)
	local params = neturl.parseQuery(query)
	return routes:execute(method, uri, params)
end
