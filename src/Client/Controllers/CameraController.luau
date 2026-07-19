--!strict
--[[
	CameraController.luau
	Dynamic combat camera with lock-on, free cam, and cinematic modes.
	Implementation in Phase 8.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = require(ReplicatedStorage.Shared)
local Signal = Shared.Framework.Signal

local CameraController = {}
CameraController.__index = CameraController

export type CameraController = typeof(setmetatable({} :: {
	OnLockOnChanged: typeof(Signal.new()),
}, CameraController))

function CameraController.new(): CameraController
	local self = setmetatable({}, CameraController) :: any
	self.OnLockOnChanged = Signal.new()
	return self
end

function CameraController.Init(self: CameraController, _container: any)
	-- Camera setup in Phase 8
end

function CameraController.Start(self: CameraController)
	-- Camera loop in Phase 8
end

return CameraController
