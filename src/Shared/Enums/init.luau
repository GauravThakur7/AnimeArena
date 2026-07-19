--!strict
--[[
	Enums/init.luau
	Re-exports all enum modules.
]]

local CombatState = require(script.CombatState)
local AttackType = require(script.AttackType)
local GameMode = require(script.GameMode)
local Rank = require(script.Rank)
local Currency = require(script.Currency)

return {
	CombatState = CombatState,
	AttackType = AttackType,
	GameMode = GameMode,
	Rank = Rank,
	Currency = Currency,
}
