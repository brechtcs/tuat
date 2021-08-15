local twitter = {}

local cqueues = require 'cqueues'
local json = require 'cjson'

function twitter:get (endpoint, params)
	local query = ''
	for k, v in pairs(params) do
		local sep = query:len() > 0 and '&' or '?'
		local param = tostring(k) .. '=' .. tostring(v)
		query = query .. sep .. param
	end

	local req = io.popen('twurl "' .. endpoint .. query .. '" 2> /dev/null')
	local data = json.decode(req:read('*all'))
	req:close()

	if self:has_rate_limit(data.errors) then
		print('rate limit reached ' .. os.date('(%H:%M:%S)'))
		cqueues.sleep(900)
		return self:get(endpoint, params)
	else
		return self:extract_errors(data)
	end
end

function twitter:extract_errors (data)
	if not data.errors then
		return data
	end
	local errs = ''
	for _, err in ipairs(data.errors) do
		errs = errs .. '\n\ttwurl error ' .. err.code .. ': ' .. err.message
	end
	return nil, errs
end

function twitter:has_rate_limit (errs)
	if not errs then
		return false
	end
	for _, err in ipairs(errs) do
		if err.code == 88 then return true end
	end
	return false
end

return twitter
