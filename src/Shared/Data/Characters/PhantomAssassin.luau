--!strict
return {
	Id = "PhantomAssassin",
	Name = "Zara Nighthollow",
	Title = "The Phantom Assassin",
	Description = "A teleporting dagger user who strikes from the shadows.",
	Lore = "Zara was erased from history by a forbidden ritual. Now she exists between moments, visible only when her daggers find their mark.",
	MaxHP = 85, MaxStamina = 115, MaxPoise = 60, BaseSpeed = 24,
	StaminaRegenRate = 15, PoiseRegenRate = 18,
	DefaultWeaponId = "DualSwords",
	PassiveId = "Vanish", UltimateId = "DeathMark", Skill1Id = "BlinkStrike",
	Archetype = "Glass Cannon", Element = "Dark",
	Strengths = { "Highest mobility", "Teleport gap closers", "Fastest in roster" },
	Weaknesses = { "Lowest HP and poise", "Dies in 3-4 hits", "No armor" },
	AnimationSetId = "DualSwords", Unlocked = false,
}
