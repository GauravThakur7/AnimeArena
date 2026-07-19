--!strict
--[[
	AnimationController.luau
	Manages animation state machine, blending, and playback.
	Implementation in Phase 7.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = require(ReplicatedStorage.Shared)
local Signal = Shared.Framework.Signal

local AnimationController = {}
AnimationController.__index = AnimationController

export type AnimationController = typeof(setmetatable({} :: {
	OnAnimationChanged: typeof(Signal.new()),
}, AnimationController))

function AnimationController.new(): AnimationController
	local self = setmetatable({}, AnimationController) :: any
	self.OnAnimationChanged = Signal.new()
	return self
end

function AnimationController.Init(self: AnimationController, _container: any)
	-- Animation setup in Phase 7
end

function AnimationController.Start(self: AnimationController)
	-- Animation state machine in Phase 7
end

return AnimationController
