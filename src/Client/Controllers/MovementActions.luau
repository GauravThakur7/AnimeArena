--!strict
--[[
	MovementActions.luau
	Handles execution of discrete movement actions: dash, roll, backstep, slide.
	These are time-based displacements that override normal movement for their duration.
	
	Separated from MovementController for single-responsibility.
	MovementController decides WHEN to act; MovementActions handles HOW.
	
	Usage:
		local actions = MovementActions.new()
		actions:StartDash(direction, distance, duration)
		actions:Tick(dt) -- advances active action
		if actions:IsActive() then ... end
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Shared.Data.Constants)

export type ActionType = "Dash" | "Roll" | "Backstep" | "Slide" | "None"

export type ActiveAction = {
	Type: ActionType,
	Direction: Vector3,
	Distance: number,
	Duration: number,
	Elapsed: number,
	StartPosition: Vector3,
}

local MovementActions = {}
MovementActions.__index = MovementActions

export type MovementActions = typeof(setmetatable({} :: {
	_active: ActiveAction?,
	_rootPart: BasePart?,
}, MovementActions))

function MovementActions.new(): MovementActions
	local self = setmetatable({}, MovementActions) :: any
	self._active = nil
	self._rootPart = nil
	return self
end

--[[
	Set the character's root part reference (needed to apply displacement).
]]
function MovementActions.SetRootPart(self: MovementActions, root: BasePart)
	self._rootPart = root
end

--[[
	Start a dash action.
]]
function MovementActions.StartDash(self: MovementActions, direction: Vector3, startPos: Vector3)
	self._active = {
		Type = "Dash",
		Direction = direction.Unit,
		Distance = Constants.DASH_DISTANCE,
		Duration = Constants.DASH_DURATION,
		Elapsed = 0,
		StartPosition = startPos,
	}
end

--[[
	Start a roll action.
]]
function MovementActions.StartRoll(self: MovementActions, direction: Vector3, startPos: Vector3)
	self._active = {
		Type = "Roll",
		Direction = direction.Unit,
		Distance = Constants.ROLL_DISTANCE,
		Duration = Constants.ROLL_DURATION,
		Elapsed = 0,
		StartPosition = startPos,
	}
end

--[[
	Start a backstep action.
]]
function MovementActions.StartBackstep(self: MovementActions, direction: Vector3, startPos: Vector3)
	self._active = {
		Type = "Backstep",
		Direction = direction.Unit,
		Distance = Constants.BACKSTEP_DISTANCE,
		Duration = Constants.BACKSTEP_DURATION,
		Elapsed = 0,
		StartPosition = startPos,
	}
end

--[[
	Advance the active action by dt seconds.
	Applies displacement to the root part using velocity.
	Returns true if action is still active, false if completed.
]]
function MovementActions.Tick(self: MovementActions, dt: number): boolean
	local action = self._active
	if not action then
		return false
	end

	action.Elapsed += dt

	if action.Elapsed >= action.Duration then
		self._active = nil
		return false
	end

	-- Apply velocity-based displacement via root part
	if self._rootPart then
		-- Ease-out curve: fast start, slow end
		local progress = action.Elapsed / action.Duration
		local easedSpeed = (1 - progress * progress) -- quadratic ease-out
		local speed = (action.Distance / action.Duration) * easedSpeed * 2 -- multiply by 2 to compensate for curve integral
		local velocity = action.Direction * speed

		-- Apply as AssemblyLinearVelocity on XZ plane, preserve Y
		local currentVel = self._rootPart.AssemblyLinearVelocity
		self._rootPart.AssemblyLinearVelocity = Vector3.new(velocity.X, currentVel.Y, velocity.Z)
	end

	return true
end

--[[
	Check if any action is currently active.
]]
function MovementActions.IsActive(self: MovementActions): boolean
	return self._active ~= nil
end

--[[
	Get the currently active action type.
]]
function MovementActions.GetActiveType(self: MovementActions): ActionType
	if self._active then
		return self._active.Type
	end
	return "None"
end

--[[
	Get progress of current action (0-1).
]]
function MovementActions.GetProgress(self: MovementActions): number
	if not self._active then
		return 0
	end
	return math.clamp(self._active.Elapsed / self._active.Duration, 0, 1)
end

--[[
	Cancel the current action immediately.
]]
function MovementActions.Cancel(self: MovementActions)
	if self._active and self._rootPart then
		-- Zero out the velocity we applied
		local currentVel = self._rootPart.AssemblyLinearVelocity
		self._rootPart.AssemblyLinearVelocity = Vector3.new(0, currentVel.Y, 0)
	end
	self._active = nil
end

--[[
	Force-stop velocity from action (called when action ends normally too).
]]
function MovementActions.StopVelocity(self: MovementActions)
	if self._rootPart then
		local currentVel = self._rootPart.AssemblyLinearVelocity
		self._rootPart.AssemblyLinearVelocity = Vector3.new(0, currentVel.Y, 0)
	end
end

return MovementActions
