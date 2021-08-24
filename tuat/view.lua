local cgi = require 'tuat.cgi'
local route = require 'tuat.routes'

local method = cgi:get_method()
local uri = cgi:get_uri()
local query = cgi:get_query()

-- get path and query from command args
local append = not cgi:is_cgi()
for _, a in ipairs(arg) do
	local ok, _, param = a:find('^%-%-(.+)$')
	if ok then
		local sep = #query > 0 and '&' or ''
		query = query .. sep .. param
		append = false
	elseif append then
		uri = uri .. '/' .. a
	end
end

-- execute route
local ok, body, status, head = route(method or 'GET', uri, query)
if not ok then
	body = 'Internal error'
	status = 500
end
if type(status) == 'table' then
	head = status
	status = nil
end

-- only print headers in CGI mode
if cgi:is_cgi() then
	if status then
		io.stdout:write(string.format('Status: %d\n', status))
	end
	for k, v in pairs(head or {}) do
		io.stdout:write(string.format('%s: %s\n', k, v))
	end
end

-- write view output
if body then
	local err = status and status > 399
	local out = err and io.stderr or io.stdout
	out:write('\n' .. body)
else
	io.stdout:write('\n')
end
