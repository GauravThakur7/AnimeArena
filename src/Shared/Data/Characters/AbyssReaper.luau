--!strict
return {
	Id = "AbyssReaper",
	Name = "Morrigan Vex",
	Title = "The Abyss Reaper",
	Description = "A cursed blade wielder who drains life from enemies.",
	Lore = "Bound to a sentient weapon that feeds on souls, Morrigan exists in a constant struggle between control and consumption.",
	MaxHP = 95, MaxStamina = 95, MaxPoise = 90, BaseSpeed = 19,
	StaminaRegenRate = 11, PoiseRegenRate = 24,
	DefaultWeaponId = "Katana",
	PassiveId = "LifeDrain", UltimateId = "AbyssalHarvest", Skill1Id = "SoulRend",
	Archetype = "Balanced", Element = "Dark",
	Strengths = { "Life steal sustain", "Strong in extended fights" },
	Weaknesses = { "Weak burst damage", "Passive requires landing hits" },
	AnimationSetId = "Katana", Unlocked = false,
}
