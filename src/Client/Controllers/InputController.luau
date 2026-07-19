--!strict
--[[
	InputController.luau
	Handles raw input from keyboard, mouse, controller, and touch.
	Translates hardware input into game actions.
	Implementation in Phase 2/4.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = require(ReplicatedStorage.Shared)
local Signal = Shared.Framework.Signal

local InputController = {}
InputController.__index = InputController

export type InputController = typeof(setmetatable({} :: {
	OnAttackInput: typeof(Signal.new()),
	OnBlockInput: typeof(Signal.new()),
	OnDodgeInput: typeof(Signal.new()),
	OnMovementInput: typeof(Signal.new()),
	OnUltimateInput: typeof(Signal.new()),
}, InputController))

function InputController.new(): InputController
	local self = setmetatable({}, InputController) :: any
	self.OnAttackInput = Signal.new()
	self.OnBlockInput = Signal.new()
	self.OnDodgeInput = Signal.new()
	self.OnMovementInput = Signal.new()
	self.OnUltimateInput = Signal.new()
	return self
end

function InputController.Init(self: InputController, _container: any)
	-- Input bindings in Phase 2
end

function InputController.Start(self: InputController)
	-- Input polling in Phase 2
end

return InputController
