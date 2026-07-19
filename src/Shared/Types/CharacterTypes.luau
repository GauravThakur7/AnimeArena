--!strict
--[[
	CharacterTypes.luau
	Type definitions for character archetypes.
]]

export type CharacterConfig = {
	Id: string,
	Name: string,
	Title: string, -- e.g., "The Crimson Demon Swordsman"
	Description: string,
	Lore: string,

	-- Base stats
	MaxHP: number,
	MaxStamina: number,
	MaxPoise: number,
	BaseSpeed: number,
	StaminaRegenRate: number,
	PoiseRegenRate: number,

	-- Weapon association
	DefaultWeaponId: string,

	-- Abilities
	PassiveId: string,
	UltimateId: string,
	Skill1Id: string?,
	Skill2Id: string?,

	-- Visual design direction
	Archetype: string, -- "Speedster" | "Tank" | "Balanced" | "Glass Cannon" | etc.
	Element: string?, -- "Fire" | "Lightning" | "Ice" | "Dark" | "Holy" | nil

	-- Strengths & weaknesses (for display/balance reference)
	Strengths: { string },
	Weaknesses: { string },

	-- Animation
	AnimationSetId: string,

	-- Availability
	Unlocked: boolean, -- default unlock state for new players
}

export type CharacterState = {
	CharacterId: string,
	CurrentHP: number,
	MaxHP: number,
	Alive: boolean,
}

return nil
