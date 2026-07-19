--!strict
--[[
	Data/init.luau
	Entry point for all game data (weapons, characters, arenas, constants).
]]

local Constants = require(script.Constants)
local Weapons = require(script.Weapons)
local Characters = require(script.Characters)
local Arenas = require(script.Arenas)

return {
	Constants = Constants,
	Weapons = Weapons,
	Characters = Characters,
	Arenas = Arenas,
}
