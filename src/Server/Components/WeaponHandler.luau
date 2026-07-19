--!strict
--[[
	WeaponHandler.luau
	Server-side component that resolves weapon data for a player.
	Provides attack parameters (frame data, damage, hitbox) based on equipped weapon
	and the current attack in the combo sequence.
	
	Usage:
		local handler = WeaponHandler.new("Katana")
		local attackData = handler:GetAttackData("Light", comboPosition)
		local frameData = handler:GetFrameData("Light", comboPosition)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = require(ReplicatedStorage.Shared)
local WeaponRegistry = require(ReplicatedStorage.Shared.Data.Weapons)

local WeaponHandler = {}
WeaponHandler.__index = WeaponHandler

export type WeaponHandler = typeof(setmetatable({} :: {
	_weaponId: string,
	_weaponConfig: any,
	_comboPosition: number, -- which hit in the combo (1, 2, 3...)
}, WeaponHandler))

function WeaponHandler.new(weaponId: string): WeaponHandler
	local self = setmetatable({}, WeaponHandler) :: any
	self._weaponId = weaponId
	self._weaponConfig = WeaponRegistry.Get(weaponId)
	self._comboPosition = 0
	return self
end

--[[
	Get the weapon config.
]]
function WeaponHandler.GetConfig(self: WeaponHandler): any?
	return self._weaponConfig
end

--[[
	Get the weapon ID.
]]
function WeaponHandler.GetWeaponId(self: WeaponHandler): string
	return self._weaponId
end

--[[
	Switch to a different weapon.
]]
function WeaponHandler.SetWeapon(self: WeaponHandler, weaponId: string)
	self._weaponId = weaponId
	self._weaponConfig = WeaponRegistry.Get(weaponId)
	self._comboPosition = 0
end

--[[
	Get attack data for the given attack type at the current combo position.
	For Light attacks, cycles through Light1, Light2, Light3, etc.
	For Heavy, always returns the Heavy attack.
]]
function WeaponHandler.GetAttackData(self: WeaponHandler, attackType: string, comboPosition: number?): any?
	if not self._weaponConfig then
		return nil
	end

	local attacks = self._weaponConfig.Attacks
	if not attacks then
		return nil
	end

	if attackType == "Light" then
		local pos = comboPosition or (self._comboPosition + 1)
		-- Cycle through Light1, Light2, Light3, etc.
		local key = "Light" .. tostring(pos)
		local data = attacks[key]
		if data then
			self._comboPosition = pos
			return data
		end
		-- Fallback to Light1 if combo position exceeds available
		self._comboPosition = 1
		return attacks["Light1"]
	elseif attackType == "Heavy" then
		self._comboPosition = 0 -- heavy resets combo
		return attacks["Heavy"]
	elseif attackType == "Dash" then
		return attacks["DashAttack"]
	elseif attackType == "Launch" then
		return attacks["Launch"]
	end

	return nil
end

--[[
	Get just the frame data for an attack.
]]
function WeaponHandler.GetFrameData(self: WeaponHandler, attackType: string, comboPosition: number?): any?
	local attackData = self:GetAttackData(attackType, comboPosition)
	if attackData then
		return attackData.FrameData
	end
	return nil
end

--[[
	Get the hitbox size for an attack.
]]
function WeaponHandler.GetHitboxSize(self: WeaponHandler, attackType: string, comboPosition: number?): Vector3
	local attackData = self:GetAttackData(attackType, comboPosition)
	if attackData and attackData.HitboxSize then
		return attackData.HitboxSize
	end
	return Vector3.new(5, 4, 6) -- default
end

--[[
	Get the hitbox offset for an attack.
]]
function WeaponHandler.GetHitboxOffset(self: WeaponHandler, attackType: string, comboPosition: number?): Vector3
	local attackData = self:GetAttackData(attackType, comboPosition)
	if attackData and attackData.HitboxOffset then
		return attackData.HitboxOffset
	end
	return Vector3.new(0, 0, -3) -- default forward
end

--[[
	Get movement speed modifier for this weapon.
]]
function WeaponHandler.GetSpeedModifier(self: WeaponHandler): number
	if self._weaponConfig then
		return self._weaponConfig.MovementSpeedModifier or 1.0
	end
	return 1.0
end

--[[
	Get stamina cost modifier for this weapon.
]]
function WeaponHandler.GetStaminaCostModifier(self: WeaponHandler): number
	if self._weaponConfig then
		return self._weaponConfig.StaminaCostModifier or 1.0
	end
	return 1.0
end

--[[
	Reset combo position (on whiff, block, or timeout).
]]
function WeaponHandler.ResetCombo(self: WeaponHandler)
	self._comboPosition = 0
end

--[[
	Get the current combo position.
]]
function WeaponHandler.GetComboPosition(self: WeaponHandler): number
	return self._comboPosition
end

return WeaponHandler
