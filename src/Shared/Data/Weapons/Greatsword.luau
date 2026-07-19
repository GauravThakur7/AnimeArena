--!strict
--[[
	Greatsword.luau
	Weapon config for the Greatsword — slow, massive damage, super armor.
	Associated character: Holy Knight Commander.
	
	Playstyle: Deliberate, punishing, trades hits with armor.
	Strengths: Huge damage, long range, armor on heavies, high poise damage.
	Weaknesses: Slow startup, long recovery, stamina-hungry.
]]

return {
	Id = "Greatsword",
	Name = "Divine Bastion",
	Description = "A holy greatsword that crushes guards and punishes aggression.",
	Category = "Greatsword",

	-- Base stats
	BaseDamage = 22,
	SwingSpeed = 0.7,
	Range = 11.0,
	Weight = 2.5,

	-- Modifiers
	MovementSpeedModifier = 0.85, -- 15% slower while equipped
	StaminaCostModifier = 1.3, -- 30% more expensive stamina costs

	-- Attack definitions
	Attacks = {
		Light1 = {
			Name = "Broad Swing",
			Damage = 18,
			StaminaCost = 10,
			PoiseDamage = 30,
			KnockbackForce = 6,
			FrameData = {
				Startup = 9,
				Active = 5,
				Recovery = 16,
				Hitstun = 22,
				Blockstun = 14,
				HitAdvantage = 6,
				BlockAdvantage = -4,
				CancelWindow = { 12, 13, 14 },
			},
			HitboxSize = Vector3.new(6, 4, 9),
			HitboxOffset = Vector3.new(0, 0, -5),
		},
		Light2 = {
			Name = "Return Swing",
			Damage = 20,
			StaminaCost = 11,
			PoiseDamage = 32,
			KnockbackForce = 7,
			FrameData = {
				Startup = 10,
				Active = 5,
				Recovery = 18,
				Hitstun = 24,
				Blockstun = 15,
				HitAdvantage = 6,
				BlockAdvantage = -5,
				CancelWindow = { 14, 15, 16 },
			},
			HitboxSize = Vector3.new(7, 4, 9),
			HitboxOffset = Vector3.new(0, 0, -5),
		},
		Light3 = {
			Name = "Downward Slam",
			Damage = 24,
			StaminaCost = 13,
			PoiseDamage = 40,
			KnockbackForce = 12,
			FrameData = {
				Startup = 12,
				Active = 6,
				Recovery = 22,
				Hitstun = 28,
				Blockstun = 16,
				HitAdvantage = 6,
				BlockAdvantage = -8,
				CancelWindow = nil,
			},
			HitboxSize = Vector3.new(5, 6, 10),
			HitboxOffset = Vector3.new(0, -1, -5),
		},
		Heavy = {
			Name = "Executioner's Strike",
			Damage = 38,
			StaminaCost = 20,
			PoiseDamage = 55,
			KnockbackForce = 16,
			FrameData = {
				Startup = 18,
				Active = 7,
				Recovery = 26,
				Hitstun = 34,
				Blockstun = 20,
				HitAdvantage = 8,
				BlockAdvantage = -12,
				CancelWindow = nil,
				ArmorFrames = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18 },
			},
			HitboxSize = Vector3.new(6, 6, 11),
			HitboxOffset = Vector3.new(0, 0, -6),
		},
		DashAttack = {
			Name = "Charging Cleave",
			Damage = 22,
			StaminaCost = 16,
			PoiseDamage = 35,
			KnockbackForce = 10,
			FrameData = {
				Startup = 8,
				Active = 6,
				Recovery = 20,
				Hitstun = 24,
				Blockstun = 14,
				HitAdvantage = 4,
				BlockAdvantage = -8,
				CancelWindow = nil,
				ArmorFrames = { 1, 2, 3, 4, 5, 6, 7, 8 },
			},
			HitboxSize = Vector3.new(6, 5, 10),
			HitboxOffset = Vector3.new(0, 0, -5),
		},
		Launch = {
			Name = "Skyward Rend",
			Damage = 26,
			StaminaCost = 18,
			PoiseDamage = 45,
			KnockbackForce = 18,
			KnockbackDirection = Vector3.new(0, 1.2, -0.2),
			FrameData = {
				Startup = 14,
				Active = 5,
				Recovery = 24,
				Hitstun = 36,
				Blockstun = 16,
				HitAdvantage = 12,
				BlockAdvantage = -12,
				CancelWindow = nil,
			},
			HitboxSize = Vector3.new(5, 7, 8),
			HitboxOffset = Vector3.new(0, 2, -4),
		},
	},

	-- Combo routes
	ComboRoutes = {
		{ Sequence = { "Light", "Light", "Light" }, CancelPoints = { 12, 14 }, TotalDamage = 62, Finisher = "Light3" },
		{ Sequence = { "Light", "Light", "Heavy" }, CancelPoints = { 12, 14 }, TotalDamage = 76, Finisher = "Heavy" },
		{ Sequence = { "Light", "Heavy" }, CancelPoints = { 12 }, TotalDamage = 56, Finisher = "Heavy" },
		{ Sequence = { "Heavy" }, CancelPoints = {}, TotalDamage = 38, Finisher = "Heavy" },
	},

	-- Abilities
	SpecialSkill = {
		Name = "Holy Guard",
		Description = "Enters a defensive stance. Next attack received is auto-parried for 1.5 seconds.",
		Cooldown = 12,
		StaminaCost = 15,
		Duration = 1.5,
		Damage = 0,
	},

	Ultimate = {
		Name = "Divine Judgment",
		Description = "Raises the greatsword skyward and brings it down with devastating holy force.",
		Cooldown = 0,
		StaminaCost = 0,
		Duration = 2.5,
		Damage = 60,
	},

	Passive = {
		Name = "Unbreakable Will",
		Description = "Poise regenerates 50% faster. Cannot be staggered by light attacks while blocking.",
		Effect = "PoiseRegenBoost",
		Value = 1.5,
	},

	-- Visual
	AnimationSet = "Greatsword",
	ExecutionAnimation = "GreatswordExecution",
}
