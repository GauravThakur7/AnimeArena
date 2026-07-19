--!strict
--[[
	ComboStateMachine.luau
	Tracks combo progression through defined routes.
	Validates whether the next input continues or breaks a combo.
	Tracks hit count and damage scaling.
	
	Usage:
		local combo = ComboStateMachine.new()
		combo:SetRoutes(routes) -- from weapon data
		combo:InputAttack("Light") -- returns next attack data or nil
		combo:Tick() -- advance timers
		combo:Reset() -- combo dropped
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = require(ReplicatedStorage.Shared)
local Constants = Shared.Data.Constants

export type ComboRouteConfig = {
	Sequence: { string }, -- e.g., {"Light", "Light", "Heavy"}
	CancelFrames: { number }, -- frame windows where next input is accepted
}

local ComboStateMachine = {}
ComboStateMachine.__index = ComboStateMachine

export type ComboStateMachine = typeof(setmetatable({} :: {
	_routes: { ComboRouteConfig },
	_currentSequence: { string },
	_hitCount: number,
	_juggleCount: number,
	_comboTimer: number, -- frames since last hit
	_comboDropWindow: number, -- max frames between hits before reset
	_activeRouteIndex: number?,
	_sequencePosition: number,
}, ComboStateMachine))

function ComboStateMachine.new(): ComboStateMachine
	local self = setmetatable({}, ComboStateMachine) :: any
	self._routes = {}
	self._currentSequence = {}
	self._hitCount = 0
	self._juggleCount = 0
	self._comboTimer = 0
	self._comboDropWindow = 30 -- ~0.5 seconds to input next attack
	self._activeRouteIndex = nil
	self._sequencePosition = 0
	return self
end

--[[
	Set available combo routes (from weapon data).
]]
function ComboStateMachine.SetRoutes(self: ComboStateMachine, routes: { ComboRouteConfig })
	self._routes = routes
end

--[[
	Register an attack input. Returns the matched route index and sequence position
	if the input continues a valid combo, or nil if it breaks.
]]
function ComboStateMachine.InputAttack(self: ComboStateMachine, attackType: string): (number?, number?)
	-- Check if this continues any valid route
	local nextSequence = table.clone(self._currentSequence)
	table.insert(nextSequence, attackType)

	-- Find matching routes
	local matchedRoute: number? = nil
	local matchedPosition: number = 0

	for i, route in self._routes do
		if self:_sequenceMatches(nextSequence, route.Sequence) then
			matchedRoute = i
			matchedPosition = #nextSequence
			break
		end
	end

	if matchedRoute then
		self._currentSequence = nextSequence
		self._activeRouteIndex = matchedRoute
		self._sequencePosition = matchedPosition
		self._hitCount += 1
		self._comboTimer = 0
		return matchedRoute, matchedPosition
	end

	-- No match: start a new combo with this input
	self:Reset()
	local singleInput = { attackType }
	for i, route in self._routes do
		if self:_sequenceMatches(singleInput, route.Sequence) then
			self._currentSequence = singleInput
			self._activeRouteIndex = i
			self._sequencePosition = 1
			self._hitCount = 1
			self._comboTimer = 0
			return i, 1
		end
	end

	-- No route starts with this attack
	return nil, nil
end

--[[
	Register a hit landing (for tracking combo count separate from inputs).
]]
function ComboStateMachine.RegisterHit(self: ComboStateMachine)
	self._comboTimer = 0
end

--[[
	Register a juggle hit.
]]
function ComboStateMachine.RegisterJuggle(self: ComboStateMachine)
	self._juggleCount += 1
end

--[[
	Advance combo timer. Should be called every tick.
	Returns true if combo was dropped due to timeout.
]]
function ComboStateMachine.Tick(self: ComboStateMachine): boolean
	if self._hitCount == 0 then
		return false
	end

	self._comboTimer += 1

	if self._comboTimer >= self._comboDropWindow then
		self:Reset()
		return true -- combo dropped
	end

	return false
end

--[[
	Get current hit count in the combo.
]]
function ComboStateMachine.GetHitCount(self: ComboStateMachine): number
	return self._hitCount
end

--[[
	Get current juggle count.
]]
function ComboStateMachine.GetJuggleCount(self: ComboStateMachine): number
	return self._juggleCount
end

--[[
	Check if juggle limit has been reached.
]]
function ComboStateMachine.IsJuggleLimitReached(self: ComboStateMachine): boolean
	return self._juggleCount >= Constants.JUGGLE_LIMIT
end

--[[
	Get the damage scaling multiplier for the current hit.
]]
function ComboStateMachine.GetDamageScaling(self: ComboStateMachine): number
	if self._hitCount <= #Constants.DAMAGE_SCALING then
		return Constants.DAMAGE_SCALING[self._hitCount]
	end
	return Constants.DAMAGE_SCALING_FLOOR
end

--[[
	Get the current active combo route config (or nil if no active combo).
]]
function ComboStateMachine.GetActiveRoute(self: ComboStateMachine): ComboRouteConfig?
	if self._activeRouteIndex then
		return self._routes[self._activeRouteIndex]
	end
	return nil
end

--[[
	Check if the current combo sequence is complete (finished the route).
]]
function ComboStateMachine.IsRouteComplete(self: ComboStateMachine): boolean
	if not self._activeRouteIndex then
		return false
	end
	local route = self._routes[self._activeRouteIndex]
	return self._sequencePosition >= #route.Sequence
end

--[[
	Get the sequence position within the active route.
]]
function ComboStateMachine.GetSequencePosition(self: ComboStateMachine): number
	return self._sequencePosition
end

--[[
	Reset combo state.
]]
function ComboStateMachine.Reset(self: ComboStateMachine)
	table.clear(self._currentSequence)
	self._hitCount = 0
	self._juggleCount = 0
	self._comboTimer = 0
	self._activeRouteIndex = nil
	self._sequencePosition = 0
end

-- ═══════════════════════════════════════════════════
-- PRIVATE
-- ═══════════════════════════════════════════════════

--[[
	Check if inputSequence matches the beginning of routeSequence.
]]
function ComboStateMachine._sequenceMatches(self: ComboStateMachine, inputSeq: { string }, routeSeq: { string }): boolean
	if #inputSeq > #routeSeq then
		return false
	end

	for i, input in inputSeq do
		if routeSeq[i] ~= input then
			return false
		end
	end

	return true
end

return ComboStateMachine
