--!strict
--[[
	NetworkTypes.luau
	Type definitions for network payloads.
]]

export type AttackRequest = {
	AttackType: string,
	Timestamp: number,
	SequenceId: number,
}

export type BlockRequest = {
	Active: boolean,
	Timestamp: number,
}

export type DodgeRequest = {
	Direction: Vector3,
	DodgeType: string, -- "Roll" | "Dash" | "Backstep" | "Sidestep"
	Timestamp: number,
}

export type StateUpdate = {
	Tick: number,
	CombatState: string,
	HP: number,
	Stamina: number,
	Poise: number,
	Position: Vector3,
	UltimateMeter: number,
	LastProcessedSequence: number,
}

export type HitConfirmation = {
	AttackerId: number,
	TargetId: number,
	Damage: number,
	HitType: string,
	Position: Vector3,
	Tick: number,
}

export type MatchStateUpdate = {
	Phase: string,
	Timer: number,
	Round: number,
	MaxRounds: number,
	Scores: { [number]: number },
}

return nil
