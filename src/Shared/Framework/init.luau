--!strict
--[[
	Framework/init.luau
	Entry point for the custom framework. Exports all framework modules.
]]

local Container = require(script.Container)
local Signal = require(script.Signal)
local Network = require(script.Network)

return {
	Container = Container,
	Signal = Signal,
	Network = Network,
}
