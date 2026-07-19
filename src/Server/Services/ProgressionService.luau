--!strict
--[[
	ProgressionService.luau
	Handles player XP, leveling, mastery, and rewards.
	Implementation in Phase 14.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = require(ReplicatedStorage.Shared)
local Signal = Shared.Framework.Signal

local ProgressionService = {}
ProgressionService.__index = ProgressionService

export type ProgressionService = typeof(setmetatable({} :: {
	_network: any,
	OnLevelUp: typeof(Signal.new()),
}, ProgressionService))

function ProgressionService.new(network: any): ProgressionService
	local self = setmetatable({}, ProgressionService) :: any
	self._network = network
	self.OnLevelUp = Signal.new()
	return self
end

function ProgressionService.Init(self: ProgressionService, _container: any)
	self._network:RegisterEvent("ProgressionUpdate")
	self._network:RegisterEvent("QuestUpdate")
end

function ProgressionService.Start(self: ProgressionService)
	-- Quest generation, XP distribution in Phase 14
end

return ProgressionService
