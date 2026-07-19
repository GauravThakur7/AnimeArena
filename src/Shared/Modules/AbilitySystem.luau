--!strict
--[[
	AbilitySystem.luau
	Manages ability cooldowns and execution state for special skills and ultimates.
	
	Each player has an AbilitySystem instance that tracks:
	- Special skill cooldown
	- Ultimate meter (separate from combat entity for flexibility)
	- Active ability state
	
	Usage:
		local abilities = AbilitySystem.new(weaponConfig)
		abilities:TrySpecial() -- returns true if off cooldown
		abilities:TryUltimate(meter) -- returns true if meter full
		abilities:Tick(dt) -- advance cooldowns
]]

local AbilitySystem = {}
AbilitySystem.__index = AbilitySystem

export type AbilityState = "Ready" | "Active" | "Cooldown"

export type AbilitySystem = typeof(setmetatable({} :: {
	_specialCooldown: number,
	_specialMaxCooldown: number,
	_specialState: AbilityState,
	_specialDuration: number,
	_specialTimer: number,
	_specialStaminaCost: number,
	_ultimateDuration: number,
	_ultimateTimer: number,
	_ultimateState: AbilityState,
	_weaponId: string,
}, AbilitySystem))

function AbilitySystem.new(weaponConfig: any): AbilitySystem
	local self = setmetatable({}, AbilitySystem) :: any

	local special = weaponConfig.SpecialSkill
	local ultimate = weaponConfig.Ultimate

	self._weaponId = weaponConfig.Id
	self._specialCooldown = 0
	self._specialMaxCooldown = if special then special.Cooldown else 10
	self._specialState = "Ready" :: AbilityState
	self._specialDuration = if special then (special.Duration or 0.5) else 0.5
	self._specialTimer = 0
	self._specialStaminaCost = if special then special.StaminaCost else 20
	self._ultimateDuration = if ultimate then (ultimate.Duration or 3.0) else 3.0
	self._ultimateTimer = 0
	self._ultimateState = "Ready" :: AbilityState

	return self
end

--[[
	Attempt to use the special skill.
	Returns true if the ability was activated.
]]
function AbilitySystem.TrySpecial(self: AbilitySystem, currentStamina: number): boolean
	if self._specialState ~= "Ready" then
		return false
	end

	if currentStamina < self._specialStaminaCost then
		return false
	end

	self._specialState = "Active"
	self._specialTimer = self._specialDuration
	return true
end

--[[
	Attempt to use the ultimate ability.
	Returns true if activated (requires full meter externally checked).
]]
function AbilitySystem.TryUltimate(self: AbilitySystem): boolean
	if self._ultimateState ~= "Ready" then
		return false
	end

	self._ultimateState = "Active"
	self._ultimateTimer = self._ultimateDuration
	return true
end

--[[
	Advance cooldown and active timers.
]]
function AbilitySystem.Tick(self: AbilitySystem, dt: number)
	-- Special skill
	if self._specialState == "Active" then
		self._specialTimer -= dt
		if self._specialTimer <= 0 then
			self._specialState = "Cooldown"
			self._specialCooldown = self._specialMaxCooldown
		end
	elseif self._specialState == "Cooldown" then
		self._specialCooldown -= dt
		if self._specialCooldown <= 0 then
			self._specialCooldown = 0
			self._specialState = "Ready"
		end
	end

	-- Ultimate
	if self._ultimateState == "Active" then
		self._ultimateTimer -= dt
		if self._ultimateTimer <= 0 then
			self._ultimateState = "Ready"
			self._ultimateTimer = 0
		end
	end
end

--[[
	Get special skill state.
]]
function AbilitySystem.GetSpecialState(self: AbilitySystem): AbilityState
	return self._specialState
end

--[[
	Get special skill cooldown remaining (seconds).
]]
function AbilitySystem.GetSpecialCooldown(self: AbilitySystem): number
	return self._specialCooldown
end

--[[
	Get special cooldown as percent (0 = ready, 1 = full cooldown).
]]
function AbilitySystem.GetSpecialCooldownPercent(self: AbilitySystem): number
	if self._specialMaxCooldown <= 0 then
		return 0
	end
	return self._specialCooldown / self._specialMaxCooldown
end

--[[
	Get ultimate state.
]]
function AbilitySystem.GetUltimateState(self: AbilitySystem): AbilityState
	return self._ultimateState
end

--[[
	Check if special is currently active (executing).
]]
function AbilitySystem.IsSpecialActive(self: AbilitySystem): boolean
	return self._specialState == "Active"
end

--[[
	Check if ultimate is currently active.
]]
function AbilitySystem.IsUltimateActive(self: AbilitySystem): boolean
	return self._ultimateState == "Active"
end

--[[
	Get stamina cost for special skill.
]]
function AbilitySystem.GetSpecialCost(self: AbilitySystem): number
	return self._specialStaminaCost
end

--[[
	Reset all cooldowns (e.g., new round).
]]
function AbilitySystem.Reset(self: AbilitySystem)
	self._specialCooldown = 0
	self._specialState = "Ready"
	self._specialTimer = 0
	self._ultimateState = "Ready"
	self._ultimateTimer = 0
end

return AbilitySystem
