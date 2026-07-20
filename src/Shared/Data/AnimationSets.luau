--!strict
--[[
	AnimationSets.luau
	Contains animation IDs organized by weapon category and action.
	
	Animation IDs are placeholders (empty strings). Replace with uploaded
	Roblox animation asset IDs when animations are created.
	
	Structure: AnimationSets[WeaponCategory][AnimationKey] = "rbxassetid://..."
]]

export type AnimationSet = {
	-- Idle & Movement
	Idle = string,
	CombatIdle = string,
	Walk = string,
	Run = string,
	Sprint = string,
	
	-- Attacks
	Light1 = string,
	Light2 = string,
	Light3 = string,
	Light4 = string?,
	Light5 = string?,
	Heavy = string,
	DashAttack = string,
	Launch = string,
	AirAttack = string?,
	GroundSlam = string?,

	-- Defense
	Block = string,
	BlockHit = string,
	Parry = string,
	ParrySuccess = string,
	GuardBreak = string,

	-- Movement Actions
	Roll = string,
	Dash = string,
	Backstep = string,
	Slide = string?,

	-- Hit Reactions
	HitLight = string,
	HitHeavy = string,
	HitLeft = string?,
	HitRight = string?,
	HitBack = string?,
	Launched = string,
	Grounded = string,
	GetUp = string,
	Stagger = string,

	-- Special
	Ultimate = string,
	SpecialSkill = string,
	Execution = string,
	BeingExecuted = string,
	Victory = string,
	Death = string,
}

local AnimationSets: { [string]: AnimationSet } = {
	Katana = {
		Idle = "",
		CombatIdle = "",
		Walk = "",
		Run = "",
		Sprint = "",
		Light1 = "",
		Light2 = "",
		Light3 = "",
		Heavy = "",
		DashAttack = "",
		Launch = "",
		Block = "",
		BlockHit = "",
		Parry = "",
		ParrySuccess = "",
		GuardBreak = "",
		Roll = "",
		Dash = "",
		Backstep = "",
		HitLight = "",
		HitHeavy = "",
		Launched = "",
		Grounded = "",
		GetUp = "",
		Stagger = "",
		Ultimate = "",
		SpecialSkill = "",
		Execution = "",
		BeingExecuted = "",
		Victory = "",
		Death = "",
	},

	Greatsword = {
		Idle = "",
		CombatIdle = "",
		Walk = "",
		Run = "",
		Sprint = "",
		Light1 = "",
		Light2 = "",
		Light3 = "",
		Heavy = "",
		DashAttack = "",
		Launch = "",
		Block = "",
		BlockHit = "",
		Parry = "",
		ParrySuccess = "",
		GuardBreak = "",
		Roll = "",
		Dash = "",
		Backstep = "",
		HitLight = "",
		HitHeavy = "",
		Launched = "",
		Grounded = "",
		GetUp = "",
		Stagger = "",
		Ultimate = "",
		SpecialSkill = "",
		Execution = "",
		BeingExecuted = "",
		Victory = "",
		Death = "",
	},

	DualSwords = {
		Idle = "",
		CombatIdle = "",
		Walk = "",
		Run = "",
		Sprint = "",
		Light1 = "",
		Light2 = "",
		Light3 = "",
		Light4 = "",
		Light5 = "",
		Heavy = "",
		DashAttack = "",
		Launch = "",
		Block = "",
		BlockHit = "",
		Parry = "",
		ParrySuccess = "",
		GuardBreak = "",
		Roll = "",
		Dash = "",
		Backstep = "",
		Slide = "",
		HitLight = "",
		HitHeavy = "",
		Launched = "",
		Grounded = "",
		GetUp = "",
		Stagger = "",
		Ultimate = "",
		SpecialSkill = "",
		Execution = "",
		BeingExecuted = "",
		Victory = "",
		Death = "",
	},
}

return table.freeze(AnimationSets)
