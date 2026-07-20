--!strict
--[[
	HolyKnightCommander.luau
	Greatsword defensive tank. Punishes aggression with superior trades.
]]

return {
	Id = "HolyKnightCommander",
	Name = "Aldric Solhart",
	Title = "The Holy Knight Commander",
	Description = "An immovable fortress who crushes opponents with overwhelming force and unbreakable defense.",
	Lore = "Commander Aldric led the final crusade against the Abyss and was the only survivor. His faith manifests as divine armor — each blow he endures strengthens his resolve, and each swing carries the weight of a thousand fallen comrades.",

	-- Base stats
	MaxHP = 120,
	MaxStamina = 85,
	MaxPoise = 140,
	BaseSpeed = 17,
	StaminaRegenRate = 10,
	PoiseRegenRate = 30,

	-- Weapon association
	DefaultWeaponId = "Greatsword",

	-- Abilities
	PassiveId = "UnbreakableWill",
	UltimateId = "DivineJudgment",
	Skill1Id = "HolyGuard",
	Skill2Id = nil,

	-- Visual design direction
	Archetype = "Tank",
	Element = "Holy",

	-- Strengths & weaknesses
	Strengths = {
		"Highest HP and poise in the roster",
		"Super armor on heavy attacks",
		"Massive damage per hit",
		"Long weapon range",
		"Poise regen passive",
	},
	Weaknesses = {
		"Slowest attack startup",
		"Longest recovery frames (very punishable on whiff)",
		"Low stamina pool",
		"Slowest movement speed",
		"Stamina-hungry attacks",
	},

	-- Animation
	AnimationSetId = "Greatsword",

	-- Availability
	Unlocked = true,
}
