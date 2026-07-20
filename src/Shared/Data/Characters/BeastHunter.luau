--!strict
return {
	Id = "BeastHunter",
	Name = "Fenris Ashclaw",
	Title = "The Beast Hunter",
	Description = "A transforming weapon user who adapts mid-fight.",
	Lore = "Fenris forged his weapon from a living beast's fang. It shifts form to match his prey — sword, axe, or whip — guided by primal instinct.",
	MaxHP = 105, MaxStamina = 95, MaxPoise = 100, BaseSpeed = 20,
	StaminaRegenRate = 12, PoiseRegenRate = 25,
	DefaultWeaponId = "Katana",
	PassiveId = "AdaptiveHunt", UltimateId = "PrimalFury", Skill1Id = "WeaponShift",
	Archetype = "Balanced", Element = nil,
	Strengths = { "Adaptable playstyle", "Can change weapon mode mid-combo" },
	Weaknesses = { "Jack of all trades", "No single dominant strength" },
	AnimationSetId = "Katana", Unlocked = false,
}
