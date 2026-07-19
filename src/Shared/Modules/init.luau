--!strict
--[[
	Modules/init.luau
	Re-exports all shared gameplay modules.
]]

local CombatStateMachine = require(script.CombatStateMachine)
local ComboStateMachine = require(script.ComboStateMachine)
local FrameDataEngine = require(script.FrameDataEngine)
local InputBuffer = require(script.InputBuffer)
local StaminaManager = require(script.StaminaManager)
local PoiseManager = require(script.PoiseManager)
local DamageCalculator = require(script.DamageCalculator)
local HitboxSystem = require(script.HitboxSystem)
local PositionHistory = require(script.PositionHistory)
local LagCompensation = require(script.LagCompensation)
local DeltaCompressor = require(script.DeltaCompressor)
local MomentumSystem = require(script.MomentumSystem)
local AbilitySystem = require(script.AbilitySystem)

return {
	CombatStateMachine = CombatStateMachine,
	ComboStateMachine = ComboStateMachine,
	FrameDataEngine = FrameDataEngine,
	InputBuffer = InputBuffer,
	StaminaManager = StaminaManager,
	PoiseManager = PoiseManager,
	DamageCalculator = DamageCalculator,
	HitboxSystem = HitboxSystem,
	PositionHistory = PositionHistory,
	LagCompensation = LagCompensation,
	DeltaCompressor = DeltaCompressor,
	MomentumSystem = MomentumSystem,
	AbilitySystem = AbilitySystem,
}
