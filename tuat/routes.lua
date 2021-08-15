local router = require 'router'

local function view_model (opts)
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
routes:get('/:view', view_model)
return routes
