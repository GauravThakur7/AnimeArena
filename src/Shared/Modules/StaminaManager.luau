--!strict
--[[
	StaminaManager.luau
	Manages stamina consumption, regeneration, and depletion checks.
	Pure logic module — no network, no Instances.
	
	Usage:
		local stamina = StaminaManager.new(100, 12, 1.5)
		stamina:Consume(15)
		stamina:Tick(dt) -- call every frame with delta time
		stamina:CanAfford(8) -- true/false
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = require(ReplicatedStorage.Shared)
local Constants = Shared.Data.Constants

local StaminaManager = {}
StaminaManager.__index = StaminaManager

export type StaminaManager = typeof(setmetatable({} :: {
	_current: number,
	_max: number,
	_regenRate: number,
	_regenDelay: number,
	_timeSinceAction: number,
	_depleted: boolean,
	_regenPaused: boolean,
}, StaminaManager))

function StaminaManager.new(max: number?, regenRate: number?, regenDelay: number?): StaminaManager
	local self = setmetatable({}, StaminaManager) :: any
	self._max = max or Constants.MAX_STAMINA
	self._current = self._max
	self._regenRate = regenRate or Constants.STAMINA_REGEN_RATE
	self._regenDelay = regenDelay or Constants.STAMINA_REGEN_DELAY
	self._timeSinceAction = 999 -- start ready to regen
	self._depleted = false
	self._regenPaused = false
	return self
end

--[[
	Advance stamina regeneration by dt seconds.
	Call this every game tick.
]]
function StaminaManager.Tick(self: StaminaManager, dt: number)
	self._timeSinceAction += dt

	-- Don't regen if paused (sprinting, blocking, etc.)
	if self._regenPaused then
		return
	end

	-- Regen after delay
	if self._timeSinceAction >= self._regenDelay then
		self._current = math.min(self._current + self._regenRate * dt, self._max)

		-- Clear depleted flag when back above 20%
		if self._depleted and self._current >= self._max * 0.2 then
			self._depleted = false
		end
	end
end

--[[
	Consume stamina. Returns true if successful, false if insufficient.
]]
function StaminaManager.Consume(self: StaminaManager, amount: number): boolean
	if self._current < amount then
		return false
	end

	self._current -= amount
	self._timeSinceAction = 0

	if self._current <= 0 then
		self._current = 0
		self._depleted = true
	end

	return true
end

--[[
	Force consume stamina (for block chip damage — doesn't fail, goes negative clamped to 0).
]]
function StaminaManager.ForceConsume(self: StaminaManager, amount: number)
	self._current = math.max(0, self._current - amount)
	self._timeSinceAction = 0

	if self._current <= 0 then
		self._depleted = true
	end
end

--[[
	Check if player can afford a stamina cost.
]]
function StaminaManager.CanAfford(self: StaminaManager, amount: number): boolean
	return self._current >= amount
end

--[[
	Get current stamina value.
]]
function StaminaManager.GetCurrent(self: StaminaManager): number
	return self._current
end

--[[
	Get max stamina value.
]]
function StaminaManager.GetMax(self: StaminaManager): number
	return self._max
end

--[[
	Get stamina as a percentage (0-1).
]]
function StaminaManager.GetPercent(self: StaminaManager): number
	return self._current / self._max
end

--[[
	Returns true if stamina is fully depleted (triggers guard break, etc.)
]]
function StaminaManager.IsDepleted(self: StaminaManager): boolean
	return self._depleted
end

--[[
	Pause regeneration (e.g., while sprinting or blocking).
]]
function StaminaManager.PauseRegen(self: StaminaManager)
	self._regenPaused = true
end

--[[
	Resume regeneration.
]]
function StaminaManager.ResumeRegen(self: StaminaManager)
	self._regenPaused = false
end

--[[
	Set stamina directly (for server reconciliation).
]]
function StaminaManager.SetCurrent(self: StaminaManager, value: number)
	self._current = math.clamp(value, 0, self._max)
	self._depleted = self._current <= 0
end

--[[
	Reset to full stamina.
]]
function StaminaManager.Reset(self: StaminaManager)
	self._current = self._max
	self._depleted = false
	self._timeSinceAction = 999
	self._regenPaused = false
end

return StaminaManager
