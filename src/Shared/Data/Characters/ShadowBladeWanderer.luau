--!strict
return {
	Id = "ShadowBladeWanderer",
	Name = "Shinji Kurogane",
	Title = "The Shadow Blade Wanderer",
	Description = "A high-mobility katana user who strikes from impossible angles.",
	Lore = "A ronin who sold his shadow to a void spirit in exchange for the ability to step between dimensions.",
	MaxHP = 95, MaxStamina = 105, MaxPoise = 80, BaseSpeed = 23,
	StaminaRegenRate = 13, PoiseRegenRate = 22,
	DefaultWeaponId = "Katana",
	PassiveId = "ShadowStep", UltimateId = "VoidSevering", Skill1Id = "DimensionSlip",
	Archetype = "Speedster", Element = "Dark",
	Strengths = { "Extreme mobility", "Teleport-based mix-ups" },
	Weaknesses = { "Low poise", "Requires precise spacing" },
	AnimationSetId = "Katana", Unlocked = false,
}
