--!strict
--[[
	DualSwords.luau
	Weapon config for Dual Swords — extremely fast, combo-heavy, aggressive.
	Associated character: Crimson Demon Swordsman.
	
	Playstyle: Relentless offense, long combo strings, overwhelm with speed.
	Strengths: Fastest attacks, most combo routes, great cancel windows.
	Weaknesses: Low per-hit damage, short range, low poise damage, no armor.
]]

return {
	Id = "DualSwords",
	Name = "Crimson Fangs",
	Description = "Twin blades that dance through the air in a flurry of crimson steel.",
	Category = "DualSwords",

	-- Base stats
	BaseDamage = 10,
	SwingSpeed = 1.5,
	Range = 6.5,
	Weight = 0.6,

	-- Modifiers
	MovementSpeedModifier = 1.1, -- 10% faster while equipped
	StaminaCostModifier = 0.8, -- 20% cheaper stamina costs

	-- Attack definitions
	Attacks = {
		Light1 = {
			Name = "Cross Slash",
			Damage = 8,
			StaminaCost = 5,
			PoiseDamage = 10,
			KnockbackForce = 2,
			FrameData = {
				Startup = 4,
				Active = 3,
				Recovery = 8,
				Hitstun = 14,
				Blockstun = 6,
				HitAdvantage = 6,
				BlockAdvantage = -1,
				CancelWindow = { 5, 6, 7 },
			},
			HitboxSize = Vector3.new(5, 3, 6),
			HitboxOffset = Vector3.new(0, 0, -3),
		},
		Light2 = {
			Name = "Twin Pierce",
			Damage = 9,
			StaminaCost = 5,
			PoiseDamage = 10,
			KnockbackForce = 2,
			FrameData = {
				Startup = 4,
				Active = 3,
				Recovery = 8,
				Hitstun = 14,
				Blockstun = 6,
				HitAdvantage = 6,
				BlockAdvantage = -1,
				CancelWindow = { 5, 6, 7 },
			},
			HitboxSize = Vector3.new(5, 3, 6),
			HitboxOffset = Vector3.new(0, 0, -3),
		},
		Light3 = {
			Name = "Spiral Cut",
			Damage = 10,
			StaminaCost = 6,
			PoiseDamage = 12,
			KnockbackForce = 3,
			FrameData = {
				Startup = 5,
				Active = 3,
				Recovery = 9,
				Hitstun = 15,
				Blockstun = 7,
				HitAdvantage = 6,
				BlockAdvantage = -2,
				CancelWindow = { 6, 7, 8 },
			},
			HitboxSize = Vector3.new(5, 3, 6),
			HitboxOffset = Vector3.new(0, 0, -3),
		},
		Light4 = {
			Name = "Demon Rend",
			Damage = 11,
			StaminaCost = 6,
			PoiseDamage = 12,
			KnockbackForce = 4,
			FrameData = {
				Startup = 5,
				Active = 4,
				Recovery = 10,
				Hitstun = 16,
				Blockstun = 8,
				HitAdvantage = 6,
				BlockAdvantage = -3,
				CancelWindow = { 7, 8, 9 },
			},
			HitboxSize = Vector3.new(5, 4, 6),
			HitboxOffset = Vector3.new(0, 0, -3),
		},
		Light5 = {
			Name = "Crimson Finisher",
			Damage = 14,
			StaminaCost = 8,
			PoiseDamage = 18,
			KnockbackForce = 8,
			FrameData = {
				Startup = 6,
				Active = 4,
				Recovery = 14,
				Hitstun = 20,
				Blockstun = 10,
				HitAdvantage = 6,
				BlockAdvantage = -6,
				CancelWindow = nil, -- finisher
			},
			HitboxSize = Vector3.new(6, 4, 7),
			HitboxOffset = Vector3.new(0, 0, -4),
		},
		Heavy = {
			Name = "Scissor Cleave",
			Damage = 22,
			StaminaCost = 12,
			PoiseDamage = 28,
			KnockbackForce = 10,
			FrameData = {
				Startup = 10,
				Active = 5,
				Recovery = 16,
				Hitstun = 24,
				Blockstun = 12,
				HitAdvantage = 8,
				BlockAdvantage = -6,
				CancelWindow = nil,
			},
			HitboxSize = Vector3.new(6, 4, 7),
			HitboxOffset = Vector3.new(0, 0, -4),
		},
		DashAttack = {
			Name = "Shadow Rush",
			Damage = 12,
			StaminaCost = 10,
			PoiseDamage = 14,
			KnockbackForce = 5,
			FrameData = {
				Startup = 3,
				Active = 4,
				Recovery = 12,
				Hitstun = 16,
				Blockstun = 8,
				HitAdvantage = 4,
				BlockAdvantage = -4,
				CancelWindow = { 8, 9, 10 },
			},
			HitboxSize = Vector3.new(5, 3, 7),
			HitboxOffset = Vector3.new(0, 0, -4),
		},
		Launch = {
			Name = "Rising Fang",
			Damage = 14,
			StaminaCost = 13,
			PoiseDamage = 18,
			KnockbackForce = 12,
			KnockbackDirection = Vector3.new(0, 1, -0.2),
			FrameData = {
				Startup = 8,
				Active = 4,
				Recovery = 18,
				Hitstun = 28,
				Blockstun = 10,
				HitAdvantage = 10,
				BlockAdvantage = -10,
				CancelWindow = nil,
			},
			HitboxSize = Vector3.new(4, 5, 6),
			HitboxOffset = Vector3.new(0, 1, -3),
		},
	},

	-- Combo routes (more routes = more mix-up potential)
	ComboRoutes = {
		{ Sequence = { "Light", "Light", "Light", "Light", "Light" }, CancelPoints = { 5, 5, 6, 7 }, TotalDamage = 52, Finisher = "Light5" },
		{ Sequence = { "Light", "Light", "Light", "Heavy" }, CancelPoints = { 5, 5, 6 }, TotalDamage = 49, Finisher = "Heavy" },
		{ Sequence = { "Light", "Light", "Heavy" }, CancelPoints = { 5, 5 }, TotalDamage = 39, Finisher = "Heavy" },
		{ Sequence = { "Light", "Heavy" }, CancelPoints = { 5 }, TotalDamage = 30, Finisher = "Heavy" },
		{ Sequence = { "Heavy" }, CancelPoints = {}, TotalDamage = 22, Finisher = "Heavy" },
		{ Sequence = { "Light", "Light", "Light", "Light", "Heavy" }, CancelPoints = { 5, 5, 6, 7 }, TotalDamage = 60, Finisher = "Heavy" },
	},

	-- Abilities
	SpecialSkill = {
		Name = "Phantom Step",
		Description = "Vanishes briefly and reappears behind the target with a cross slash.",
		Cooldown = 6,
		StaminaCost = 18,
		Duration = 0.3,
		Damage = 18,
	},

	Ultimate = {
		Name = "Demon's Thousand Cuts",
		Description = "Unleashes an unstoppable barrage of 20 slashes in all directions.",
		Cooldown = 0,
		StaminaCost = 0,
		Duration = 4.0,
		Damage = 70,
	},

	Passive = {
		Name = "Blood Frenzy",
		Description = "Each consecutive hit increases attack speed by 5% (max 25%). Resets on miss or taking damage.",
		Effect = "ComboSpeedBoost",
		Value = 0.05,
	},

	-- Visual
	AnimationSet = "DualSwords",
	ExecutionAnimation = "DualSwordsExecution",
}
