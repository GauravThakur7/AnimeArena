--!strict
--[[
	DataService.luau
	Manages player data persistence via ProfileStore.
	Handles loading, saving, and session management.
	Full implementation in Phase 14.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = require(ReplicatedStorage.Shared)
local Signal = Shared.Framework.Signal

local DataService = {}
DataService.__index = DataService

export type DataService = typeof(setmetatable({} :: {
	_profiles: { [Player]: any },
	OnProfileLoaded: typeof(Signal.new()),
	OnProfileReleased: typeof(Signal.new()),
}, DataService))

function DataService.new(): DataService
	local self = setmetatable({}, DataService) :: any
	self._profiles = {}
	self.OnProfileLoaded = Signal.new()
	self.OnProfileReleased = Signal.new()
	return self
end

function DataService.Init(self: DataService, _container: any)
	Players.PlayerAdded:Connect(function(player)
		self:_loadProfile(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:_releaseProfile(player)
	end)

	-- Handle players already in game (late server start)
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			self:_loadProfile(player)
		end)
	end
end

function DataService.Start(self: DataService)
	-- Bind to close for graceful shutdown
	game:BindToClose(function()
		for player in self._profiles do
			self:_releaseProfile(player)
		end
	end)
end

function DataService.GetProfile(self: DataService, player: Player): any?
	return self._profiles[player]
end

function DataService._loadProfile(self: DataService, player: Player)
	-- ProfileStore integration in Phase 14
	-- For now, store a placeholder
	self._profiles[player] = { UserId = player.UserId, Data = {} }
	self.OnProfileLoaded:Fire(player)
end

function DataService._releaseProfile(self: DataService, player: Player)
	if self._profiles[player] then
		self._profiles[player] = nil
		self.OnProfileReleased:Fire(player)
	end
end

return DataService
