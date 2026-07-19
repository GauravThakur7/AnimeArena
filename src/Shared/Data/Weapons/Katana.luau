--!strict
--[[
	Katana.luau
	Weapon config for the Katana — balanced speed and range.
	Associated character: Storm Ronin.
	
	Playstyle: Precise cuts, good cancel windows, rewards timing.
	Strengths: Fast startup, good frame advantage, versatile combos.
	Weaknesses: Moderate damage per hit, no super armor.
]]

return {
	Id = "Katana",
	Name = "Storm Edge",
	Description = "A lightning-forged katana that rewards precision and timing.",
	Category = "Katana",

	-- Base stats
	BaseDamage = 14,
	SwingSpeed = 1.2,
	Range = 8.5,
	Weight = 1.0,

	-- Modifiers
	MovementSpeedModifier = 1.0, -- no penalty
	StaminaCostModifier = 0.9, -- 10% cheaper stamina costs

	-- Attack definitions
	Attacks = {
		Light1 = {
			Name = "Quick Slash",
			Damage = 12,
			StaminaCost = 7,
			PoiseDamage = 15,
			KnockbackForce = 3,
			FrameData = {
				Startup = 5,
				Active = 3,
				Recovery = 10,
				Hitstun = 16,
				Blockstun = 8,
				HitAdvantage = 6,
				BlockAdvantage = -2,
				CancelWindow = { 7, 8, 9 },
			},
			HitboxSize = Vector3.new(4, 3, 7),
			HitboxOffset = Vector3.new(0, 0, -4),
		},
		Light2 = {
			Name = "Rising Cut",
			Damage = 13,
			StaminaCost = 7,
			PoiseDamage = 15,
			KnockbackForce = 4,
			FrameData = {
				Startup = 6,
				Active = 3,
				Recovery = 11,
				Hitstun = 17,
				Blockstun = 9,
				HitAdvantage = 6,
				BlockAdvantage = -3,
				CancelWindow = { 8, 9, 10 },
			},
			HitboxSize = Vector3.new(4, 4, 7),
			HitboxOffset = Vector3.new(0, 1, -4),
		},
		Light3 = {
			Name = "Thrust",
			Damage = 15,
			StaminaCost = 8,
			PoiseDamage = 18,
			KnockbackForce = 6,
			FrameData = {
				Startup = 7,
				Active = 4,
				Recovery = 14,
				Hitstun = 20,
				Blockstun = 10,
				HitAdvantage = 6,
				BlockAdvantage = -5,
				CancelWindow = nil, -- finisher, no cancel
			},
			HitboxSize = Vector3.new(3, 3, 9),
			HitboxOffset = Vector3.new(0, 0, -5),
		},
		Heavy = {
			Name = "Overhead Cleave",
			Damage = 28,
			StaminaCost = 14,
			PoiseDamage = 35,
			KnockbackForce = 10,
			FrameData = {
				Startup = 12,
				Active = 5,
				Recovery = 18,
				Hitstun = 26,
				Blockstun = 14,
				HitAdvantage = 8,
				BlockAdvantage = -8,
				CancelWindow = nil,
			},
			HitboxSize = Vector3.new(5, 5, 8),
			HitboxOffset = Vector3.new(0, 0, -4),
		},
		DashAttack = {
			Name = "Flash Step",
			Damage = 16,
			StaminaCost = 12,
			PoiseDamage = 20,
			KnockbackForce = 8,
			FrameData = {
				Startup = 4,
				Active = 4,
				Recovery = 16,
				Hitstun = 18,
				Blockstun = 10,
				HitAdvantage = 2,
				BlockAdvantage = -6,
				CancelWindow = nil,
			},
			HitboxSize = Vector3.new(4, 3, 8),
			HitboxOffset = Vector3.new(0, 0, -5),
		},
		Launch = {
			Name = "Rising Thunder",
			Damage = 18,
			StaminaCost = 15,
			PoiseDamage = 25,
			KnockbackForce = 14,
			KnockbackDirection = Vector3.new(0, 1, -0.3),
			FrameData = {
				Startup = 10,
				Active = 4,
				Recovery = 20,
				Hitstun = 30,
				Blockstun = 12,
				HitAdvantage = 10,
				BlockAdvantage = -10,
				CancelWindow = nil,
			},
			HitboxSize = Vector3.new(4, 5, 6),
			HitboxOffset = Vector3.new(0, 1, -3),
		},
	},

	-- Combo routes
	ComboRoutes = {
		{ Sequence = { "Light", "Light", "Light" }, CancelPoints = { 7, 8 }, TotalDamage = 40, Finisher = "Light3" },
		{ Sequence = { "Light", "Light", "Heavy" }, CancelPoints = { 7, 8 }, TotalDamage = 53, Finisher = "Heavy" },
		{ Sequence = { "Light", "Heavy" }, CancelPoints = { 7 }, TotalDamage = 40, Finisher = "Heavy" },
		{ Sequence = { "Heavy" }, CancelPoints = {}, TotalDamage = 28, Finisher = "Heavy" },
	},

	-- Abilities
	SpecialSkill = {
		Name = "Lightning Draw",
		Description = "A blindingly fast iaijutsu strike that hits all enemies in a line.",
		Cooldown = 8,
		StaminaCost = 20,
		Duration = 0.4,
		Damage = 25,
	},

	Ultimate = {
		Name = "Thousand Volt Barrage",
		Description = "Unleashes a storm of lightning-infused slashes in rapid succession.",
		Cooldown = 0, -- meter-based
		StaminaCost = 0,
		Duration = 3.0,
		Damage = 80,
	},

	Passive = {
		Name = "Storm Conductor",
		Description = "Successful parries charge the blade, increasing next attack damage by 30%.",
		Effect = "ParryDamageBoost",
		Value = 1.3,
	},

	-- Visual
	AnimationSet = "Katana",
	ExecutionAnimation = "KatanaExecution",
}
