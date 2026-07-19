--!strict
--[[
	CombatTypes.luau
	Type definitions for the combat system.
]]

export type FrameData = {
	Startup: number,
	Active: number,
	Recovery: number,
	Hitstun: number,
	Blockstun: number,
	HitAdvantage: number,
	BlockAdvantage: number,
	CancelWindow: { number }?,
	IFrames: { number }?,
	ArmorFrames: { number }?,
}

export type AttackData = {
	Name: string,
	Damage: number,
	StaminaCost: number,
	PoiseDamage: number,
	KnockbackForce: number,
	KnockbackDirection: Vector3?,
	FrameData: FrameData,
	HitboxSize: Vector3,
	HitboxOffset: Vector3,
}

export type ComboRoute = {
	Sequence: { string },
	CancelPoints: { number },
	TotalDamage: number,
	Finisher: string,
}

export type StaminaState = {
	Current: number,
	Max: number,
	RegenRate: number,
	RegenDelay: number,
	LastActionTime: number,
}

export type PoiseState = {
	Current: number,
	Max: number,
	RegenRate: number,
	RegenDelay: number,
	LastHitTime: number,
}

export type CombatSnapshot = {
	Tick: number,
	State: string,
	Position: Vector3,
	Rotation: CFrame,
	HP: number,
	Stamina: number,
	Poise: number,
	UltimateMeter: number,
	ComboCount: number,
}

return nil
