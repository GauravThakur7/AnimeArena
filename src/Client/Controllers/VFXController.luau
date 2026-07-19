--!strict
--[[
	VFXController.luau
	Manages visual effects (slash trails, particles, hit sparks).
	Implementation in Phase 10.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = require(ReplicatedStorage.Shared)
local Signal = Shared.Framework.Signal

local VFXController = {}
VFXController.__index = VFXController

export type VFXController = typeof(setmetatable({} :: {
	OnEffectRequested: typeof(Signal.new()),
}, VFXController))

function VFXController.new(): VFXController
	local self = setmetatable({}, VFXController) :: any
	self.OnEffectRequested = Signal.new()
	return self
end

function VFXController.Init(self: VFXController, _container: any)
	-- VFX pool setup in Phase 10
end

function VFXController.Start(self: VFXController)
	-- VFX listeners in Phase 10
end

return VFXController
