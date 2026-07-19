--!strict
--[[
	Types/init.luau
	Re-exports all type modules for convenience.
	Usage: local Types = require(Shared.Types)
]]

local CombatTypes = require(script.CombatTypes)
local WeaponTypes = require(script.WeaponTypes)
local CharacterTypes = require(script.CharacterTypes)
local NetworkTypes = require(script.NetworkTypes)
local ArenaTypes = require(script.ArenaTypes)
local EconomyTypes = require(script.EconomyTypes)
local UITypes = require(script.UITypes)

-- Re-export (Luau doesn't support re-exporting types directly,
-- but requiring this module gives access to all sub-modules)
return {
	CombatTypes = CombatTypes,
	WeaponTypes = WeaponTypes,
	CharacterTypes = CharacterTypes,
	NetworkTypes = NetworkTypes,
	ArenaTypes = ArenaTypes,
	EconomyTypes = EconomyTypes,
	UITypes = UITypes,
}
