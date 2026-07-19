--!strict
--[[
	CombatController.luau
	Client-side combat prediction and state management.
	Sends requests to server, plays animations immediately.
	Implementation in Phase 2.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = require(ReplicatedStorage.Shared)
local Signal = Shared.Framework.Signal

local CombatController = {}
CombatController.__index = CombatController

export type CombatController = typeof(setmetatable({} :: {
	_network: any,
	OnStateChanged: typeof(Signal.new()),
	OnComboUpdate: typeof(Signal.new()),
}, CombatController))

function CombatController.new(network: any): CombatController
	local self = setmetatable({}, CombatController) :: any
	self._network = network
	self.OnStateChanged = Signal.new()
	self.OnComboUpdate = Signal.new()
	return self
end

function CombatController.Init(self: CombatController, _container: any)
	-- Listen for server state updates (Phase 2)
end

function CombatController.Start(self: CombatController)
	-- Prediction loop in Phase 2
end

return CombatController
