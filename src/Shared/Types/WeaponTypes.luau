--!strict
--[[
	WeaponTypes.luau
	Type definitions for the weapon system.
]]

local CombatTypes = require(script.Parent.CombatTypes)

export type WeaponConfig = {
	Id: string,
	Name: string,
	Description: string,
	Category: string, -- "Katana" | "Greatsword" | "DualSwords" | "Longsword" | etc.

	-- Base stats
	BaseDamage: number,
	SwingSpeed: number, -- multiplier (1.0 = normal)
	Range: number, -- studs
	Weight: number, -- affects movement speed

	-- Modifiers
	MovementSpeedModifier: number, -- multiplier while equipped
	StaminaCostModifier: number, -- multiplier on stamina costs

	-- Combat data
	Attacks: { [string]: CombatTypes.AttackData },
	ComboRoutes: { CombatTypes.ComboRoute },

	-- Abilities
	SpecialSkill: AbilityConfig?,
	Ultimate: AbilityConfig?,
	Passive: PassiveConfig?,

	-- Visual
	AnimationSet: string, -- which animation set to use
	ExecutionAnimation: string?,
}

export type AbilityConfig = {
	Name: string,
	Description: string,
	Cooldown: number,
	StaminaCost: number,
	Duration: number?,
	Damage: number?,
}

export type PassiveConfig = {
	Name: string,
	Description: string,
	Effect: string, -- key for passive effect handler
	Value: number?,
}

return nil
