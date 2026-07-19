--!strict
--[[
	AttackType.luau
	All possible attack types.
]]

local AttackType = {
	Light = "Light",
	Heavy = "Heavy",
	Running = "Running",
	Dash = "Dash",
	Air = "Air",
	Launch = "Launch",
	GroundSlam = "GroundSlam",
	Execution = "Execution",
	Ultimate = "Ultimate",
	Riposte = "Riposte",
	Special1 = "Special1",
	Special2 = "Special2",
}

export type AttackType = typeof(AttackType[any])

return table.freeze(AttackType)
