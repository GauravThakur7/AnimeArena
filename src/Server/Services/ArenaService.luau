--!strict
--[[
	ArenaService.luau
	Manages arena loading, rotation, and environment setup.
	Implementation in Phase 13.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = require(ReplicatedStorage.Shared)
local Signal = Shared.Framework.Signal

local ArenaService = {}
ArenaService.__index = ArenaService

export type ArenaService = typeof(setmetatable({} :: {
	_currentArenaId: string?,
	OnArenaLoaded: typeof(Signal.new()),
}, ArenaService))

function ArenaService.new(): ArenaService
	local self = setmetatable({}, ArenaService) :: any
	self._currentArenaId = nil
	self.OnArenaLoaded = Signal.new()
	return self
end

function ArenaService.Init(self: ArenaService, _container: any)
	-- Arena config loading in Phase 13
end

function ArenaService.Start(self: ArenaService)
	-- Default arena load in Phase 13
end

return ArenaService
