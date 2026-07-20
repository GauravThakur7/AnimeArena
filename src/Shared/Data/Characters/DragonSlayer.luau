--!strict
return {
	Id = "DragonSlayer",
	Name = "Gorm Ironbane",
	Title = "The Dragon Slayer",
	Description = "A massive weapon wielder with unstoppable super armor.",
	Lore = "Gorm hunted the last dragon alone. The beast's spine became his weapon, and its fire became his will.",
	MaxHP = 130, MaxStamina = 80, MaxPoise = 160, BaseSpeed = 15,
	StaminaRegenRate = 9, PoiseRegenRate = 35,
	DefaultWeaponId = "Greatsword",
	PassiveId = "DragonScale", UltimateId = "CataclysmSlam", Skill1Id = "DragonCharge",
	Archetype = "Tank", Element = "Fire",
	Strengths = { "Highest poise in the game", "Super armor on most attacks" },
	Weaknesses = { "Slowest character", "Extremely punishable on whiff" },
	AnimationSetId = "Greatsword", Unlocked = false,
}
