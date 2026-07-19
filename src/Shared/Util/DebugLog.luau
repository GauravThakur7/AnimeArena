--!strict
--[[
	DebugLog.luau
	Centralized debug logging utility. Toggle ENABLED to false to silence all debug output.
	
	Usage:
		local DebugLog = require(...)
		DebugLog:Log("Combat", "Player attacked with Light")
		DebugLog:Warn("Network", "Rate limited player X")
]]

local RunService = game:GetService("RunService")

local DebugLog = {}

-- ═══════════════════════ TOGGLE THIS ═══════════════════════
local ENABLED = true
-- ═══════════════════════════════════════════════════════════

local SIDE = if RunService:IsServer() then "[SERVER]" else "[CLIENT]"

function DebugLog.Log(category: string, message: string)
	if ENABLED then
		print(`{SIDE} [{category}] {message}`)
	end
end

function DebugLog.Warn(category: string, message: string)
	if ENABLED then
		warn(`{SIDE} [{category}] {message}`)
	end
end

return table.freeze(DebugLog)
