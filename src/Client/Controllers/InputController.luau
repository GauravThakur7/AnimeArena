--!strict
--[[
	InputController.luau
	Handles raw input from keyboard, mouse, controller, and touch.
	Translates hardware input into game action signals.
]]

local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Signal = Shared.Framework.Signal

local InputController = {}
InputController.__index = InputController

export type InputController = typeof(setmetatable({} :: {
	OnAttackInput: typeof(Signal.new()),
	OnBlockInput: typeof(Signal.new()),
	OnDodgeInput: typeof(Signal.new()),
	OnMovementInput: typeof(Signal.new()),
	OnUltimateInput: typeof(Signal.new()),
	OnParryInput: typeof(Signal.new()),
	_blockHeld: boolean,
}, InputController))

function InputController.new(): InputController
	local self = setmetatable({}, InputController) :: any
	self.OnAttackInput = Signal.new()
	self.OnBlockInput = Signal.new()
	self.OnDodgeInput = Signal.new()
	self.OnMovementInput = Signal.new()
	self.OnUltimateInput = Signal.new()
	self.OnParryInput = Signal.new()
	self._blockHeld = false
	return self
end

function InputController.Init(self: InputController, _container: any)
	-- Keyboard & Mouse bindings
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		self:_onInputBegan(input)
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		self:_onInputEnded(input)
	end)
end

function InputController.Start(self: InputController)
	-- Controller support via ContextActionService can be added here
end

function InputController.IsBlockHeld(self: InputController): boolean
	return self._blockHeld
end

-- ═══════════════════════════════════════════════════
-- PRIVATE
-- ═══════════════════════════════════════════════════

function InputController._onInputBegan(self: InputController, input: InputObject)
	local keyCode = input.KeyCode
	local inputType = input.UserInputType

	-- Light Attack: Left Mouse Button
	if inputType == Enum.UserInputType.MouseButton1 then
		self.OnAttackInput:Fire("Light")
		return
	end

	-- Heavy Attack: Right Mouse Button
	if inputType == Enum.UserInputType.MouseButton2 then
		self.OnAttackInput:Fire("Heavy")
		return
	end

	-- Block: Q (hold)
	if keyCode == Enum.KeyCode.Q then
		self._blockHeld = true
		self.OnBlockInput:Fire(true)
		return
	end

	-- Parry: E (tap)
	if keyCode == Enum.KeyCode.E then
		self.OnParryInput:Fire()
		return
	end

	-- Dodge/Roll: Left Alt
	if keyCode == Enum.KeyCode.LeftAlt then
		self.OnDodgeInput:Fire("Roll")
		return
	end

	-- Dash: Left Shift + Direction (simplified: just shift for now)
	if keyCode == Enum.KeyCode.LeftShift then
		self.OnDodgeInput:Fire("Dash")
		return
	end

	-- Backstep: Left Control
	if keyCode == Enum.KeyCode.LeftControl then
		self.OnDodgeInput:Fire("Backstep")
		return
	end

	-- Ultimate: R
	if keyCode == Enum.KeyCode.R then
		self.OnUltimateInput:Fire()
		return
	end
end

function InputController._onInputEnded(self: InputController, input: InputObject)
	local keyCode = input.KeyCode

	-- Block release
	if keyCode == Enum.KeyCode.Q then
		self._blockHeld = false
		self.OnBlockInput:Fire(false)
		return
	end
end

return InputController
