--!strict
--[[
	StormRonin.luau
	Lightning-infused longsword user. Balanced and precise.
]]

return {
	Id = "StormRonin",
	Name = "Raiden Murakami",
	Title = "The Storm Ronin",
	Description = "A wandering swordsman who channels lightning through his blade for devastating precision strikes.",
	Lore = "Raiden was struck by divine lightning atop Mount Tenrai and survived. The storm now lives within him — each swing crackles with voltage, and each parry returns thunder upon his enemies.",

	-- Base stats
	MaxHP = 100,
	MaxStamina = 100,
	MaxPoise = 100,
	BaseSpeed = 20,
	StaminaRegenRate = 12,
	PoiseRegenRate = 25,

	-- Weapon association
	DefaultWeaponId = "Katana",

	-- Abilities
	PassiveId = "StormConductor",
	UltimateId = "ThousandVoltBarrage",
	Skill1Id = "LightningDraw",
	Skill2Id = nil,

	-- Visual design direction
	Archetype = "Balanced",
	Element = "Lightning",

	-- Strengths & weaknesses
	Strengths = {
		"Well-rounded stats with no major weaknesses",
		"Fast startup on light attacks",
		"Parry passive rewards defensive play",
		"Good range for a medium weapon",
	},
	Weaknesses = {
		"No super armor on any attack",
		"Average damage per hit",
		"No inherent combo extension tools",
		"Passive requires successful parries to activate",
	},

	-- Animation
	AnimationSetId = "Katana",

	-- Availability
	Unlocked = true,
}
