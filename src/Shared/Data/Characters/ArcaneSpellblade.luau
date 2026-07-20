--!strict
return {
	Id = "ArcaneSpellblade",
	Name = "Lyra Astenveil",
	Title = "The Arcane Spellblade",
	Description = "A hybrid fighter who weaves magic between sword strikes.",
	Lore = "A prodigy of both the Mage Academy and the Knight Order, Lyra fuses arcane energy into every swing.",
	MaxHP = 90, MaxStamina = 110, MaxPoise = 75, BaseSpeed = 20,
	StaminaRegenRate = 14, PoiseRegenRate = 20,
	DefaultWeaponId = "Katana",
	PassiveId = "ArcaneInfusion", UltimateId = "MeteorStrike", Skill1Id = "ArcaneBurst",
	Archetype = "Glass Cannon", Element = "Fire",
	Strengths = { "Ranged special attacks", "High burst damage combos" },
	Weaknesses = { "Low HP and poise", "Long cooldowns on specials" },
	AnimationSetId = "Katana", Unlocked = false,
}
