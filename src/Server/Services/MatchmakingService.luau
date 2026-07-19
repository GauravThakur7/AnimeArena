--!strict
--[[
	MatchmakingService.luau
	Handles queue management and match creation.
	Implementation in Phase 13.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = require(ReplicatedStorage.Shared)
local Signal = Shared.Framework.Signal

local MatchmakingService = {}
MatchmakingService.__index = MatchmakingService

export type MatchmakingService = typeof(setmetatable({} :: {
	_network: any,
	OnMatchFound: typeof(Signal.new()),
}, MatchmakingService))

function MatchmakingService.new(network: any): MatchmakingService
	local self = setmetatable({}, MatchmakingService) :: any
	self._network = network
	self.OnMatchFound = Signal.new()
	return self
end

function MatchmakingService.Init(self: MatchmakingService, _container: any)
	self._network:RegisterEvent("QueueRequest")
	self._network:RegisterEvent("QueueCancel")
	self._network:RegisterEvent("MatchFound")
	self._network:RegisterEvent("MatchState")
end

function MatchmakingService.Start(self: MatchmakingService)
	-- Matchmaking loop in Phase 13
end

return MatchmakingService
