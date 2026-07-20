--!strict
--[[
	CrimsonDemonSwordsman.luau
	Fast, stylish dual-sword fighter. Rewards aggressive combo play.
]]

return {
	Id = "CrimsonDemonSwordsman",
	Name = "Kael Ashvorn",
	Title = "The Crimson Demon Swordsman",
	Description = "A relentless blade dancer who overwhelms opponents with endless combo strings.",
	Lore = "Once a noble duelist, Kael fell to a demon's curse that grants him inhuman speed at the cost of his humanity. Each fight feeds the demon within, and each combo pushes him closer to losing himself entirely.",

	-- Base stats
	MaxHP = 90,
	MaxStamina = 110,
	MaxPoise = 70,
	BaseSpeed = 22,
	StaminaRegenRate = 14,
	PoiseRegenRate = 20,

	-- Weapon association
	DefaultWeaponId = "DualSwords",

	-- Abilities
	PassiveId = "BloodFrenzy",
	UltimateId = "DemonsThousandCuts",
	Skill1Id = "PhantomStep",
	Skill2Id = nil,

	-- Visual design direction
	Archetype = "Speedster",
	Element = "Dark",

	-- Strengths & weaknesses
	Strengths = {
		"Fastest attack speed in the game",
		"Longest combo chains (5-hit light string)",
		"Excellent cancel windows for mix-ups",
		"High stamina pool for sustained pressure",
	},
	Weaknesses = {
		"Lowest HP in the roster",
		"Low poise — easily interrupted",
		"Short weapon range",
		"Low per-hit damage",
	},

	-- Animation
	AnimationSetId = "DualSwords",

	-- Availability
	Unlocked = true,
}
