--!strict
--[[
	Shared/init.luau
	Root module for all shared code. Provides access to framework, types, enums, data, modules, and utilities.
]]

local Framework = require(script.Framework)
local Types = require(script.Types)
local Enums = require(script.Enums)
local Data = require(script.Data)
local Modules = require(script.Modules)
local Util = require(script.Util)

return {
	Framework = Framework,
	Types = Types,
	Enums = Enums,
	Data = Data,
	Modules = Modules,
	Util = Util,
}
