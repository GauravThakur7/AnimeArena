--!strict
--[[
	MovementController.luau
	Client-side character movement with momentum.
	Implementation in Phase 4.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = require(ReplicatedStorage.Shared)
local Signal = Shared.Framework.Signal

local MovementController = {}
MovementController.__index = MovementController

export type MovementController = typeof(setmetatable({} :: {
	OnDash: typeof(Signal.new()),
	OnRoll: typeof(Signal.new()),
}, MovementController))

function MovementController.new(): MovementController
	local self = setmetatable({}, MovementController) :: any
	self.OnDash = Signal.new()
	self.OnRoll = Signal.new()
	return self
end

function MovementController.Init(self: MovementController, _container: any)
	-- Movement setup in Phase 4
end

function MovementController.Start(self: MovementController)
	-- Movement loop in Phase 4
end

return MovementController
