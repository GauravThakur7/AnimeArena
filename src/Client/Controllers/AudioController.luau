--!strict
--[[
	AudioController.luau
	Manages all audio playback (SFX, music, ambient).
	Implementation in Phase 11.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = require(ReplicatedStorage.Shared)
local Signal = Shared.Framework.Signal

local AudioController = {}
AudioController.__index = AudioController

export type AudioController = typeof(setmetatable({} :: {
	OnMusicChanged: typeof(Signal.new()),
}, AudioController))

function AudioController.new(): AudioController
	local self = setmetatable({}, AudioController) :: any
	self.OnMusicChanged = Signal.new()
	return self
end

function AudioController.Init(self: AudioController, _container: any)
	-- Sound pool setup in Phase 11
end

function AudioController.Start(self: AudioController)
	-- Audio listeners in Phase 11
end

return AudioController
