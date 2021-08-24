local etlua = require 'etlua'
local json = require 'cjson'

local View = {}

function View:new (o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function View:format (format)
	if format == 'json' then
		return json.encode(self), { ['Content-Type'] = 'application/json' }
	end
	return nil, 'unsupported output format: ' .. format
end

function View:render ()
	local layout, err = self:layout()
	if not layout then
		return err
	end

	local dir = os.getenv('TUAT_LAYOUTS')
	local path = string.format('%s/%s.etlua', dir, layout)
	local fd, err = io.open(path)
	if not fd then
		return nil, 'could not open layout\n' ..  err
	end

	local template = fd:read('*all')
	fd:close()

	return etlua.render(template, { this = self }), { ['Content-Type'] = 'text/html' }
end

function View:layout()
	return nil, 'no layout provided for model'
end

return View
