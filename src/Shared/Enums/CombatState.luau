--!strict
--[[
	CombatState.luau
	All possible combat states for the state machine.
]]

local CombatState = {
	Idle = "Idle",
	Walking = "Walking",
	Running = "Running",
	Sprinting = "Sprinting",
	Attacking = "Attacking",
	HeavyAttacking = "HeavyAttacking",
	Blocking = "Blocking",
	Parrying = "Parrying",
	ParrySuccess = "ParrySuccess",
	Riposte = "Riposte",
	Staggered = "Staggered",
	Launched = "Launched",
	Juggled = "Juggled",
	Grounded = "Grounded",
	GettingUp = "GettingUp",
	Rolling = "Rolling",
	Dashing = "Dashing",
	Backstepping = "Backstepping",
	Sidestepping = "Sidestepping",
	GuardBroken = "GuardBroken",
	Executing = "Executing",
	BeingExecuted = "BeingExecuted",
	UsingUltimate = "UsingUltimate",
	SuperArmor = "SuperArmor",
	AirAttacking = "AirAttacking",
	GroundSlamming = "GroundSlamming",
	WallBounce = "WallBounce",
	GroundBounce = "GroundBounce",
	Ragdoll = "Ragdoll",
	Sliding = "Sliding",
	Dead = "Dead",
}

export type CombatState = typeof(CombatState[any])

return table.freeze(CombatState)
