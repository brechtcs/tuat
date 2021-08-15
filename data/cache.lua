local driver = require 'luasql.sqlite3'

local env = driver.sqlite3()
local sqlite = os.getenv('TUAT_CACHE') .. '/tuat.sqlite'
local conn = assert(env:connect(sqlite))

-----------------
-- Setup cache --
-----------------

if not conn:setautocommit(true) then
	print 'failed to enable autocommit'
end

local FOLLOWS_TABLE = [[
	Follows (
		from_id INTEGER NOT NULL,
		to_id INTEGER NOT NULL,
		update_time INTEGER NOT NULL,
		UNIQUE(from_id, to_id) ON CONFLICT REPLACE
	);
]]

function create_table (descr)
	local ok, err = conn:execute('CREATE TABLE IF NOT EXISTS ' .. descr)
	if not ok then print(err) end
end

create_table(FOLLOWS_TABLE)

----------------------
-- Expose interface --
----------------------

local INSERT_FOLLOW = "INSERT INTO Follows VALUES(%d, %d, %d)"
local SELECT_FOLLOWS_FROM = "SELECT to_id FROM Follows WHERE from_id = %d"
local SELECT_FOLLOWS_TO = "SELECT from_id FROM Follows WHERE to_id = %d"
local PRUNE_FOLLOWS = "DELETE FROM Follows WHERE update_time < %d AND (from_id = %d OR to_id = %d)"

local cache = {}

function cache:insert_follows (from_ids, to_ids, start_time)
	assert(type(start_time) == 'number')
	local tr, err = cache:start_transaction()
	if not tr then return nil, err end

	local follows = 0
	for _, to in ipairs (to_ids) do
		for _, from in ipairs(from_ids) do
			local query = INSERT_FOLLOW:format(from, to, start_time)
			local rows, err = conn:execute(query)
			if rows then
				follows = follows + rows
			else
				cache:rollback_transaction()
				return nil, err
			end
		end
	end

	local ok, err = cache:commit_transaction()
	if not ok then return nil, err end
	return follows
end

function cache:prune_follows (user_id, before_time)
	local query = PRUNE_FOLLOWS:format(before_time, user_id, user_id)
	return conn:execute(query)
end

function cache:list_followers (ids)
	local query = ''
	for _, id in ipairs(ids) do
		local sep = query:len() > 0 and ' INTERSECT ' or ''
		local followers = SELECT_FOLLOWS_TO:format(id)
		query = query .. sep .. followers
	end
	return cache:fetch_list(query)
end

function cache:list_influences (ids)
	local query = ''
	for _, id in ipairs(ids) do
		local sep = query:len() > 0 and ' INTERSECT ' or ''
		local influences = SELECT_FOLLOWS_FROM:format(id)
		query = query .. sep .. influences
	end
	return cache:fetch_list(query)
end

function cache:list_mutuals (ids)
	local query = ''
	for _, id in ipairs(ids) do
		local sep = query:len() > 0 and ' INTERSECT ' or ''
		local from = SELECT_FOLLOWS_FROM:format(id)
		local to = SELECT_FOLLOWS_TO:format(id)
		local mutuals = string.format('%s INTERSECT %s', from, to)
		query = query .. sep .. mutuals
	end
	return cache:fetch_list(query)
end

function cache:fetch_list (query)
	local cursor, err = conn:execute(query)
	if not cursor then return nil, err end

	local list = {}
	while true do
		local row = cursor:fetch()
		if not row then break end
		table.insert(list, row)
	end
	return list
end

function cache:commit_transaction ()
	local ok = conn:commit()
	if not ok then
		return nil, 'failed to commit transaction'
	elseif not conn:setautocommit(true) then
		return nil, 'failed to reenable autocommit'
	end
	return ok
end

function cache:rollback_transaction ()
	return conn:rollback()
end

function cache:start_transaction ()
	local ok = conn:setautocommit(false)
	if not ok then
		return nil, 'failed to disable autocommit'
	else return ok end
end

return cache
