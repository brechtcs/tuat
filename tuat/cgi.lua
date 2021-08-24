local URI_PATTERN = '^%s([^?]*)'
local CGI = {
	method = os.getenv('REQUEST_METHOD');
	base = os.getenv('TUAT_BASE_URI') or '';
	uri = os.getenv('REQUEST_URI');
	query = os.getenv('QUERY_STRING');
}

function CGI:is_cgi ()
	return self.method ~= nil
end

function CGI:get_method ()
	return self.method or 'GET'
end

function CGI:get_uri ()
	if self.uri then
		local pattern = URI_PATTERN:format(self.base)
		local _, _, uri = self.uri:find(pattern)
		return uri
	else
		return '/'
	end
end

function CGI:get_query ()
	return self.query or ''
end

return CGI
