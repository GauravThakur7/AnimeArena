--!strict
--[[
	PoiseManager.luau
	Manages poise (stagger resistance) for a combat entity.
	When poise reaches 0, the entity is staggered regardless of current state.
	
	Usage:
		local poise = PoiseManager.new(100)
		poise:TakeDamage(20) -- returns true if stagger triggered
		poise:Tick(dt) -- regeneration
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Shared.Data.Constants)

local PoiseManager = {}
PoiseManager.__index = PoiseManager

export type PoiseManager = typeof(setmetatable({} :: {
	_current: number,
	_max: number,
	_regenRate: number,
	_regenDelay: number,
	_timeSinceHit: number,
	_broken: boolean,
}, PoiseManager))

function PoiseManager.new(max: number?, regenRate: number?, regenDelay: number?): PoiseManager
	local self = setmetatable({}, PoiseManager) :: any
	self._max = max or Constants.MAX_POISE
	self._current = self._max
	self._regenRate = regenRate or Constants.POISE_REGEN_RATE
	self._regenDelay = regenDelay or Constants.POISE_REGEN_DELAY
	self._timeSinceHit = 999
	self._broken = false
	return self
end

--[[
	Advance poise regeneration by dt seconds.
]]
function PoiseManager.Tick(self: PoiseManager, dt: number)
	self._timeSinceHit += dt

	if self._timeSinceHit >= self._regenDelay then
		self._current = math.min(self._current + self._regenRate * dt, self._max)

		if self._broken and self._current >= self._max then
			self._broken = false
		end
	end
end

--[[
	Apply poise damage. Returns true if poise broke (stagger should trigger).
]]
function PoiseManager.TakeDamage(self: PoiseManager, amount: number): boolean
	self._current = math.max(0, self._current - amount)
	self._timeSinceHit = 0

	if self._current <= 0 and not self._broken then
		self._broken = true
		return true -- Stagger triggered
	end

	return false
end

--[[
	Get current poise value.
]]
function PoiseManager.GetCurrent(self: PoiseManager): number
	return self._current
end

--[[
	Get max poise.
]]
function PoiseManager.GetMax(self: PoiseManager): number
	return self._max
end

--[[
	Returns true if poise is currently broken.
]]
function PoiseManager.IsBroken(self: PoiseManager): boolean
	return self._broken
end

--[[
	Set poise directly (server reconciliation).
]]
function PoiseManager.SetCurrent(self: PoiseManager, value: number)
	self._current = math.clamp(value, 0, self._max)
	self._broken = self._current <= 0
end

--[[
	Reset to full poise.
]]
function PoiseManager.Reset(self: PoiseManager)
	self._current = self._max
	self._broken = false
	self._timeSinceHit = 999
end

return PoiseManager
