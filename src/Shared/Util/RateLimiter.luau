--!strict
--[[
	RateLimiter.luau
	Server-side rate limiter for remote events.
	Prevents clients from spamming requests.
	
	Usage:
		local limiter = RateLimiter.new()
		limiter:SetLimit("Attack", 10) -- max 10 per second
		
		if limiter:Check(player, "Attack") then
			-- process request
		else
			-- rate limited, reject
		end
]]

local RateLimiter = {}
RateLimiter.__index = RateLimiter

export type RateLimiter = typeof(setmetatable(
	{} :: {
		_limits: { [string]: number },
		_history: { [Player]: { [string]: { number } } },
	},
	RateLimiter
))

function RateLimiter.new(): RateLimiter
	local self = setmetatable({}, RateLimiter) :: any
	self._limits = {}
	self._history = {}
	return self
end

--- Set the maximum number of calls per second for an action.
function RateLimiter.SetLimit(self: RateLimiter, action: string, maxPerSecond: number)
	self._limits[action] = maxPerSecond
end

--- Check if a player's action is within rate limits. Returns true if allowed.
function RateLimiter.Check(self: RateLimiter, player: Player, action: string): boolean
	local limit = self._limits[action]
	if not limit then
		return true -- No limit set, allow
	end

	-- Initialize player history
	if not self._history[player] then
		self._history[player] = {}
	end
	if not self._history[player][action] then
		self._history[player][action] = {}
	end

	local history = self._history[player][action]
	local now = os.clock()

	-- Remove entries older than 1 second
	while #history > 0 and (now - history[1]) > 1.0 do
		table.remove(history, 1)
	end

	-- Check limit
	if #history >= limit then
		return false
	end

	-- Record this call
	table.insert(history, now)
	return true
end

--- Clean up data for a player who left.
function RateLimiter.RemovePlayer(self: RateLimiter, player: Player)
	self._history[player] = nil
end

--- Reset all history (useful for testing).
function RateLimiter.Reset(self: RateLimiter)
	table.clear(self._history)
end

return RateLimiter
