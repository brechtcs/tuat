local BASE = os.getenv('TUAT_BASE_URI') or ''

local neturl = require 'net.url'
local router = require 'router'

local function redirect ()
	return nil, 301, { Location = BASE .. '/timeline' }
end

local function intent (opts)
	local view = opts.view
	opts.view = nil
	if not view then
		return 'no view specified for intent', 400
	end
	local query = neturl.buildQuery(opts)
	if #query > 0 then
		query = '?' .. query
	end
	io.stderr:write(query)
	return nil, 301, { Location = BASE .. '/' .. view .. query }
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
routes:get('/intent', intent)
routes:get('/:view', view)

return function (method, uri, query)
	local params = neturl.parseQuery(query)
	return routes:execute(method, uri, params)
end
