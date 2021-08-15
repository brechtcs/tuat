local cli = require 'cliargs'
local routes = require 'tuat.routes'

local view = table.remove(arg, 1)
cli:set_name('tuat view ' .. view)
cli:option('--user=USERS', 'user screen names to pass into view', {})
cli:option('--format=FORMAT', 'output format for view data')

local opts, msg = cli:parse(arg)
if opts then
	local ok, res = routes:execute('GET', view, opts)
	if ok then
		io.stdout:write(res)
		os.exit(0)
	end
end

io.stderr:write(res or msg)
os.exit(1)
